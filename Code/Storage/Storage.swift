import SwiftObserver
import PromiseKit

class Storage: Observer
{
    // MARK: - Initialize
    
    init(with file: ItemFile, database: ItemDatabase)
    {
        self.file = file
        self.database = database
    }
    
    // MARK: - Respond to App Life Cycle
    
    func appDidLaunch()
    {
        Store.shared.loadItems(from: file)

        guard isUsingDatabase else { return }
        
        tryToStartSyncing
        {
            success, errorMessage in
            
            guard success else
            {
                let c2a = "Make sure your Mac is connected to your iCloud account, then retry using iCloud via the menu option \"Data → Start Using iCloud\"."
                self.informUserDatabaseIsUnavailable(error: errorMessage,
                                                     callToAction: c2a)
                return
            }
        }
    }
    
    func windowLostFocus() { Store.shared.saveItems(to: file) }
    
    func appWillTerminate() { Store.shared.saveItems(to: file) }
    
    // MARK: - Keep Track of Database Availability
    
    func databaseAvailabilityMayHaveChanged()
    {
        guard self.isUsingDatabase else { return }
        
        if database.isAvailable != true
        {
            log(error: "Invalid state: Using database while it's POSSIBLY unavailable: Is availabe: \(String(describing: database.isAvailable))")
        }
    
        firstly
        {
            database.checkAvailability()
        }
        .done
        {
            if case .unavailable(let message) = $0
            {
                self.stopContinuousSyncing()
                
                let c2a = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account, then select the menu option \"Data → Start Using iCloud\"."
                
                self.informUserDatabaseIsUnavailable(error: message,
                                                     callToAction: c2a)
            }
        }
        .catch { log($0) }
    }
    
    // MARK: - Opting In and Out of Syncing Database & Store
    
    var isUsingDatabase: Bool
    {
        set
        {
            guard newValue else
            {
                stopContinuousSyncing()
                return
            }
            
            tryToStartSyncing
            {
                success, errorMessage in
                
                guard success else
                {
                    let c2a = "Make sure your Mac is connected to your iCloud account, then retry activating iCloud via the menu option \"Data → Start Using iCloud\"."
                    
                    self.informUserDatabaseIsUnavailable(error: errorMessage,
                                                         callToAction: c2a)
                    
                    return
                }
            }
        }
        
        get { return databaseUsageFlag.value }
    }
    
    // MARK: - Initiate Database Use
    
    private func tryToStartSyncing(handleSuccess: @escaping (Bool, String?) -> Void)
    {
        guard Store.shared.root != nil else
        {
            log(error: "Store has no root. Create file and Store root before trying top sync Store with Database.")
            stopContinuousSyncing()
            return
        }
        
        firstly
        {
            database.checkAvailability()
        }
        .done
        {
            availability in
            
            switch availability
            {
            case .available:
                self.doInitialSync
                {
                    success in
                    
                    guard success else
                    {
                        self.stopContinuousSyncing()
                        handleSuccess(false, "The initial Sync up with iCloud didn't work.")
                        return
                    }
                    
                    self.startContinuousSyncing()
                    handleSuccess(true, nil)
                }
            case .unavailable(let message):
                self.stopContinuousSyncing()
                handleSuccess(false, message)
            }
        }
        .catch { log($0) }
    }
    
    private func doInitialSync(handleSuccess: @escaping (Bool) -> Void)
    {
        guard let storeRoot = Store.shared.root else
        {
            log(error: "Store has no root. Create file and Store root before syncing Store with Database.")
            handleSuccess(false)
            return
        }
        
        firstly
        {
            self.database.fetchTrees()
        }
        .done
        {
            roots in
            
            guard let databaseRoot = roots.first else
            {
                // no items in database
                
                firstly
                {
                    self.database.resetItemTree(with: storeRoot)
                }
                .done
                {
                    handleSuccess(true)
                }
                .catch
                {
                    log($0)
                    handleSuccess(false)
                }
                
                return
            }
            
            if storeRoot.isLeaf && !databaseRoot.isLeaf
            {
                // no user items in Store but in iCloud
                
                Store.shared.update(root: databaseRoot)
                self.file.save(databaseRoot)
                handleSuccess(true)
                return
            }
            
            if storeRoot.isIdentical(to: databaseRoot)
            {
                // Store and iCloud are identical
                
                handleSuccess(true)
                return
            }
            
            firstly
            {
                self.database.fetchUpdates()
            }
            .then
            {
                (edits: [Edit]) -> Promise<Void> in
                
                if edits.isEmpty
                {
                    // Store changed but noone changed iCloud
                    
                    return self.database.resetItemTree(with: storeRoot)
                }
                
                // FIXME: conflicting item trees: ask user which to use!
                
                Store.shared.update(root: databaseRoot)
                self.file.save(databaseRoot)
                
                return Promise()
            }
            .catch { log($0) }
        }
        .catch { log($0) }
        
    }
    
    // MARK: - Continuous Syncing
    
    private func startContinuousSyncing()
    {
        self.databaseUsageFlag.value = true
        
        self.observeDatabase()
        self.observeStore()
    }
    
    private func stopContinuousSyncing()
    {
        databaseUsageFlag.value = false
        
        stopObservingDatabase()
        stopObserving(Store.shared)
    }
    
    // MARK: - Observe Database & Store
    
    private func observeDatabase()
    {
        let databaseMessenger = database.messenger
        
        observe(databaseMessenger)
        {
            guard let edit = $0 else { return }
            
            //log("applying edit from db to store: \(edit)")
            
            Store.shared.apply(edit)
        }
    }
    
    private func stopObservingDatabase()
    {
        stopObserving(database.messenger)
    }
    
    private func observeStore()
    {
        observe(Store.shared)
        {
            guard case .wasEdited(let edit) = $0 else { return }
            
            self.storeWasEdited(edit)
        }
    }
    
    private func storeWasEdited(_ edit: Edit)
    {
        //log("applying edit from store to db: \(edit)")
        
        guard database.isAvailable == true else
        {
            log(error: "Invalid state: Applying store edits to database while database is unavailable.")
            return
        }
        
        database.apply(edit)
    }
    
    // MARK: - Database
    
    private func informUserDatabaseIsUnavailable(error: String?,
                                                 callToAction: String)
    {
        log("This issue occured: \(error ?? "Flowlist couldn't determine your iCloud account status.")\n\(callToAction)\n\n",
            title: "Whoops, no iCloud?",
            forUser: true)
    }
    
    private var databaseUsageFlag = PersistentFlag(key: "IsUsingDatabase",
                                                   defaultValue: true)
    
    let database: ItemDatabase
    
    // MARK: - File
    
    let file: ItemFile
}

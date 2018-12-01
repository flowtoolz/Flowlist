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
        
        firstly
        {
            startSyncing()
        }
        .done
        {
            if case .unavailable(let message) = $0
            {
                self.stopContinuousSyncing()
                let c2a = "Make sure your Mac is connected to your iCloud account, then retry using iCloud via the menu option \"Data → Start Using iCloud\"."
                self.informUserDatabaseIsUnavailable(error: message,
                                                     callToAction: c2a)
            }
        }
        .catch
        {
            self.stopContinuousSyncing()
            log($0)
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
                let c2a = self.c2aLostICloud
                self.informUserDatabaseIsUnavailable(error: message,
                                                     callToAction: c2a)
            }
        }
        .catch
        {
            self.stopContinuousSyncing()
            log($0)
        }
    }
    
    private let c2aLostICloud = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account, then select the menu option \"Data → Start Using iCloud\"."
    
    // MARK: - Keep Track of Network Reachability
    
    func networkBecame(reachable: Bool)
    {
        defer { networkIsReachable = reachable }
        
        guard let wasReachable = networkIsReachable, wasReachable != reachable else
        {
            return
        }
        
        if reachable
        {
            print("network became reachable again.")
        }
        else
        {
            print("network became unreachable again.")
        }
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
            
            firstly
            {
                startSyncing()
            }
            .done
            {
                if case .unavailable(let message) = $0
                {
                    self.stopContinuousSyncing()
                    let c2a = "Make sure your Mac is connected to your iCloud account, then retry activating iCloud via the menu option \"Data → Start Using iCloud\"."
                    self.informUserDatabaseIsUnavailable(error: message,
                                                         callToAction: c2a)
                }
            }
            .catch
            {
                self.stopContinuousSyncing()
                log($0)
            }
        }
        
        get { return databaseUsageFlag.value }
    }
    
    // MARK: - Initiate Database Use
    
    private func startSyncing() -> Promise<SyncStartResult>
    {
        guard Store.shared.root != nil else
        {
            return Promise(error: StorageError.storeHasNoRoot("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            database.checkAvailability()
        }
        .then
        {
            (availability: Availability) -> Promise<SyncStartResult> in
            
            switch availability
            {
            case .available:
                return firstly
                {
                    self.doInitialSync()
                }
                .map
                {
                    self.startContinuousSyncing()
                    
                    return .success
                }
                
            case .unavailable(let message):
                return Promise.value(.unavailable(message))
            }
        }
    }
    
    private enum SyncStartResult
    {
        case success, unavailable(_ message: String)
    }
    
    private func doInitialSync() -> Promise<Void>
    {
        guard let storeRoot = Store.shared.root else
        {
            return Promise(error: StorageError.storeHasNoRoot("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
            
        return firstly
        {
            self.database.fetchTrees()
        }
        .then
        {
            (roots: [Item]) -> Promise<Void> in
            
            guard let databaseRoot = roots.first else
            {
                // no items in database
                
                return self.database.resetItemTree(with: storeRoot)
            }
            
            if storeRoot.isLeaf && !databaseRoot.isLeaf
            {
                // no user items in Store but in iCloud
                
                Store.shared.update(root: databaseRoot)
                self.file.save(databaseRoot)
                
                return Promise()
            }
            
            if storeRoot.isIdentical(to: databaseRoot)
            {
                // Store and iCloud are identical
                
                return Promise()
            }
            
            return firstly
            {
                self.database.fetchUpdates()
            }
            .then
            {
                (edits: [Edit]) -> Promise<Void> in
                
                // TODO: how do we know the store actually changed since the last sync?
                
                if edits.isEmpty
                {
                    // Store changed but noone changed iCloud
                    
                    return self.database.resetItemTree(with: storeRoot)
                }
                
                // conflicting item trees
                
                return firstly
                {
                    Dialog.default.askWhetherToPreferICloud()
                }
                .then
                {
                    (preferICloud: Bool) -> Promise<Void> in
                    
                    if preferICloud
                    {
                        Store.shared.update(root: databaseRoot)
                        self.file.save(databaseRoot)
                        return Promise()
                    }
                    else
                    {
                        return self.database.resetItemTree(with: storeRoot)
                    }
                }
            }
        }
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
    
    // MARK: - Network Reachability
    
    private var networkIsReachable: Bool?
    
    // MARK: - Database
    
    private func informUserDatabaseIsUnavailable(error: String,
                                                 callToAction: String)
    {
        log("Flowlist could not access iCloud. This issue occured: \(error)\n\(callToAction)\n\n",
            title: "Whoops, no iCloud?",
            forUser: true)
    }
    
    private var databaseUsageFlag = PersistentFlag(key: "IsUsingDatabase",
                                                   defaultValue: true)
    
    let database: ItemDatabase
    
    // MARK: - File
    
    let file: ItemFile
    
    // MARK: - Errors
    
    private enum StorageError: Error
    {
        case storeHasNoRoot(_ message: String)
    }
}

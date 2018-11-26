import SwiftObserver

class Storage: Observer
{
    // MARK: - Initialize
    
    init(with file: ItemFile, database: Database)
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
    
        database.checkAvailability
        {
            available, errorMessage in
            
            guard available else
            {
                self.stopContinuousSyncing()
                
                let c2a = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account, then select the menu option \"Data → Start Using iCloud\"."
                
                self.informUserDatabaseIsUnavailable(error: errorMessage,
                                                     callToAction: c2a)

                return
            }
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
        
        database.checkAvailability
        {
            available, errorMessage in
            
            guard available else
            {
                self.stopContinuousSyncing()
                handleSuccess(false, errorMessage)
                return
            }
            
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
        }
    }
    
    private func doInitialSync(handleSuccess: @escaping (Bool) -> Void)
    {
        guard let storeRoot = Store.shared.root else
        {
            log(error: "Store has no root. Create file and Store root before syncing Store with Database.")
            handleSuccess(false)
            return
        }
        
        self.database.fetchItemTree
        {
            success, databaseRoot in
            
            guard success else
            {
                handleSuccess(false)
                return
            }
            
            guard let databaseRoot = databaseRoot else
            {
                self.database.resetItemTree(with: storeRoot,
                                            handleSuccess: handleSuccess)
                
                return
            }
            
            // FIX: Make Merge Policy more intelligent... handle offline periods etc...
            Store.shared.update(root: databaseRoot)
            self.file.save(databaseRoot)
            
            handleSuccess(true)
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
    
    let database: Database
    
    // MARK: - File
    
    let file: ItemFile
}

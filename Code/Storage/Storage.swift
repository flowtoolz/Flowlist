import SwiftObserver

class Storage: Observer
{
    // MARK: - Congigurable Singleton That Logs Error if it Doesn't Exist
    
    static var shared: Storage?
    {
        if sharedInstance == nil
        {
            log(error: "Shared Storage instance hasn't been created. Use Storage.initSharedStorage(...) for that.")
        }
        
        return sharedInstance
    }
    
    static func initSharedStorage(with file: ItemFile, database: Database)
    {
        sharedInstance = Storage(with: file, database: database)
    }
    
    private static var sharedInstance: Storage?
    
    private init(with file: ItemFile, database: Database)
    {
        self.file = file
        self.database = database
    }
    
    // MARK: - Respond to App Life Cycle
    
    func appDidLaunch()
    {
        guard isUsingDatabase else
        {
            Store.shared.loadItems(from: file)
            return
        }
        
        guard let database = database else
        {
            log(error: "No database has been provided.")
            return
        }
        
        database.updateAvailability
        {
            available, errorMessage in
        
            guard available else
            {
                Store.shared.loadItems(from: self.file)
                
                let c2a = "Make sure your Mac is connected to your iCloud account, then restart Flowlist.\n\nOr: Stop using iCloud via the \"Data\" menu."
                
                self.informUserDatabaseIsUnavailable(error: errorMessage,
                                                     callToAction: c2a)
                return
            }
            
            Store.shared.resetWithItems(fromAvailableDatabase: database)
            {
                guard $0 else
                {
                    Store.shared.loadItems(from: self.file)
                    log(error: "Could not reset store with database items.")
                    return
                }
            }
        }
    }
    
    func windowLostFocus() { Store.shared.saveItems(to: file) }
    
    func appWillTerminate() { Store.shared.saveItems(to: file) }
    
    // MARK: - Opting In and Out of Syncing Database & Store
    
    var isUsingDatabase: Bool
    {
        set
        {
            if newValue { tryToStartUsingDatabase() }
            else { stopUsingDatabase() }
        }
        
        get { return databaseUsageFlag.value }
    }
    
    private func tryToStartUsingDatabase()
    {
        guard let database = database else
        {
            log(error: "No database has been provided.")
            return
        }
        
        database.updateAvailability
        {
            available, errorMessage in
            
            guard available else
            {
                let c2a = "Make sure your Mac is connected to your iCloud account, then retry activating iCloud via the \"Data\" menu."
                
                self.informUserDatabaseIsUnavailable(error: errorMessage,
                                                     callToAction: c2a)
                return
            }
            
            self.startUsingDatabase()
        }
    }
    
    private func startUsingDatabase()
    {
        // TODO: sync up data
        
        databaseUsageFlag.value = true
        
        observeDatabase()
        observeStore()
    }
    
    private func stopUsingDatabase()
    {
        // TODO: do anything? sync up data one last time if db still available?

        databaseUsageFlag.value = false
        
        stopObservingDatabase()
        stopObserving(Store.shared)
    }
    
    // MARK: - Sync Database & Store
    
    private func observeDatabase()
    {
        guard let databaseMessenger = database?.messenger else
        {
            log(error: "No database has been provided.")
            return
        }
        
        observe(databaseMessenger)
        {
            guard let edit = $0 else { return }
            
            //log("applying edit from db to store: \(edit)")
            
            Store.shared.apply(edit)
        }
    }
    
    private func stopObservingDatabase()
    {
        stopObserving(database?.messenger)
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
        
        guard let databaseAvailable = database?.isAvailable else
        {
            log(warning: "Hadn't checked database availability before editing. Or no databse has been provided.")
            
            database?.updateAvailability
            {
                _, _ in self.database?.apply(edit)
            }
            
            return
        }
        
        if databaseAvailable { database?.apply(edit) }
    }
    
    // MARK: - Keep Track of Database Availability
    
    func databaseAvailabilityMayHaveChanged()
    {
        guard self.isUsingDatabase else { return }
        
        database?.updateAvailability
        {
            available, errorMessage in
            
            guard available else
            {
                let c2a = "Make sure your Mac is connected to your iCloud account, then restart Flowlist.\n\nOr: Stop using iCloud via the \"Data\" menu."
                
                self.informUserDatabaseIsUnavailable(error: errorMessage,
                                                     callToAction: c2a)
                
                log(error: "Database became unavailable. Case not yet handled.")
                // TODO: handle this. don't opt out. maybe remember timestamp of last full sync for later merge
                return
            }
            
            log(error: "Database became available again. Case not yet handled.")
            // TODO: handle this as well. resync, merge...
        }
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
    
    private weak var database: Database?
    
    // MARK: - File
    
    private weak var file: ItemFile?
}

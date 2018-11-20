import SwiftObserver

class Storage: Observer
{
    // MARK: - Initialization & Configuration
    
    static let shared = Storage()
    
    private init()
    {
        if isUsingDatabase { observeStore() }
    }
    
    func configure(with file: ItemFile, database: Database)
    {
        self.file = file
        
        stopObservingDatabase()
        
        self.database = database
        
        if isUsingDatabase { observeDatabase() }
    }
    
    // MARK: - Respond to App Life Cycle
    
    func appDidLaunch()
    {
        updateDatabaseAvailability
        {
            _, _ in self.initializeStoreItems()
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
        guard let databaseIsAvailable = database?.isAvailable else
        {
            log(warning: "Hadn't checked database availability before opting into using it. Or no databse has been provided.")
            
            updateDatabaseAvailability
            {
                db, error in
                
                guard db != nil else
                {
                    self.didTryToStartUsingUnavailableDatabase()
                    return
                }
                
                self.startUsingDatabase()
            }
            
            return
        }
        
        guard databaseIsAvailable else
        {
            didTryToStartUsingUnavailableDatabase()
            return
        }
        
        startUsingDatabase()
    }
    
    private func didTryToStartUsingUnavailableDatabase()
    {
        log(error: "Could not start using database because it's unavailable. Case is unhandled.")
        // TODO: handle this case. do anything at all?
    }
    
    private func startUsingDatabase()
    {
        databaseUsageFlag.value = true
        
        observeDatabase()
        observeStore()
        
        // TODO: sync up data
    }
    
    private func stopUsingDatabase()
    {
        databaseUsageFlag.value = false
        
        stopObservingDatabase()
        stopObserving(Store.shared)
        
        // TODO: do anything? sync up data one last time if db still available?
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
            
            updateDatabaseAvailability
            {
                db, error in db?.apply(edit)
            }
            
            return
        }
        
        if databaseAvailable { database?.apply(edit) }
    }
    
    // MARK: - Basic Use Cases
    
    private func initializeStoreItems()
    {
        guard isUsingDatabase else
        {
            Store.shared.loadItems(from: file)
            return
        }
        
        resetStoreWithDatabaseItems()
    }
    
    private func resetStoreWithDatabaseItems()
    {
        updateDatabaseAvailability
        {
            database, errorMessage in
            
            guard let database = database else
            {
                log(error: "Database is unavailable.")
                Store.shared.loadItems(from: self.file)
                return
            }
            
            database.fetchItemTree()
            {
                if let root = $0
                {
                    Store.shared.update(root: root)
                }
                else
                {
                    log(error: "Couldn't fetch item tree. Falling back to file.")
                    Store.shared.loadItems(from: self.file)
                }
            }
        }
    }
    
    private func resetDatabaseWithStoreItems()
    {
        guard let root = Store.shared.root else
        {
            log(error: "No root in store")
            return
        }
        
        updateDatabaseAvailability
        {
            database, _ in
            
            database?.resetItemTree(with: root)
        }
    }
    
    // MARK: - Database
    
    func databaseAvailabilityMayHaveChanged()
    {
        updateDatabaseAvailability
        {
            db, errorMessage in
            
            guard self.isUsingDatabase else { return }
            
            let databaseAvailable = db != nil
            
            guard databaseAvailable else
            {
                self.informUserThatDatabaseIsUnavailable(error: errorMessage)
                log(error: "Database became unavailable. Case not yet handled.")
                // TODO: handle this. don't opt out. maybe remember timestamp of last full sync for later merge
                return
            }
            
            log(error: "Database became available again. Case not yet handled.")
            // TODO: handle this as well. resync, merge...
        }
    }
    
    private func updateDatabaseAvailability(action: @escaping (Database?, String?) -> Void)
    {
        guard let database = database else
        {
            log(error: "No database has been provided.")
            action(nil, nil)
            return
        }
        
        database.updateAvailability
        {
            available, errorMessage in
            
            guard available else
            {
                action(nil, errorMessage)
                return
            }
            
            action(database, nil)
        }
    }
    
    private func informUserThatDatabaseIsUnavailable(error: String?)
    {
        log("This issue occured: \(error ?? "Flowlist couldn't determine your iCloud account status.")\n\nMake sure your Mac is connected to your iCloud account, then restart Flowlist.\n\nOr: Stop using iCloud via the \"Data\" menu.\n",
            title: "Whoops, no iCloud?",
            forUser: true)
    }
    
    private weak var database: Database?
    
    private var databaseUsageFlag = PersistentFlag(key: "IsUsingDatabase",
                                                   defaultValue: true)
    
    // MARK: - File
    
    private weak var file: ItemFile?
}

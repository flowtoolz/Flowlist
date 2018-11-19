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
        databaseIsAvailable = nil
        
        if isUsingDatabase { observeDatabase() }
    }
    
    // MARK: - App Life Cycle
    
    func appDidLaunch()
    {
        initializeStoreItems()
    }
    
    func windowLostFocus()
    {
        saveStoreItemsToFile()
    }
    
    func appWillTerminate()
    {
        saveStoreItemsToFile()
    }
    
    // MARK: - Opting In and Out of Syncing Database & Store
    
    var isUsingDatabase: Bool
    {
        set
        {
            if newValue
            {
                tryToStartUsingDatabase()
            }
            else
            {
                stopObservingDatabase()
                stopObserving(Store.shared)
                databaseUsageFlag.value = false
                
                // TODO: anything else? sync up data one last time??
            }
        }
        
        get { return databaseUsageFlag.value }
    }
    
    private func tryToStartUsingDatabase()
    {
        doAfterAvailabilityCheck
        {
            guard $0 != nil else { return }
            
            // TODO: sync up data
            
            self.observeDatabase()
            self.observeStore()
            self.databaseUsageFlag.value = true
        }
    }
  
    // MARK: - Sync Database & Store
    
    private func observeDatabase()
    {
        guard let databaseMessenger = database?.messenger else
        {
            log(error: "No database has been provided.")
            databaseIsAvailable = false
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
        
        guard let databaseAvailable = databaseIsAvailable else
        {
            log(warning: "Hadn't checked database availability before editing.")
            
            doAfterAvailabilityCheck { $0?.apply(edit) }
            
            return
        }
        
        if databaseAvailable { database?.apply(edit) }
    }
    
    // MARK: - Basic Use Cases
    
    private func initializeStoreItems()
    {
        guard isUsingDatabase else
        {
            loadStoreItemsFromFile()
            return
        }
        
        resetStoreWithDatabaseItems()
    }
    
    private func resetStoreWithDatabaseItems()
    {
        doAfterAvailabilityCheck
        {
            guard let database = $0 else
            {
                self.loadStoreItemsFromFile()
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
                    self.loadStoreItemsFromFile()
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
        
        doAfterAvailabilityCheck
        {
            $0?.resetItemTree(with: root)
        }
    }
    
    // MARK: - Database
    
    private func doAfterAvailabilityCheck(action: @escaping (Database?) -> Void)
    {
        guard let database = database else
        {
            log(error: "No database has been provided.")
            databaseIsAvailable = false
            action(nil)
            return
        }
        
        database.checkAvailability
        {
            available, errorMessage in
            
            self.databaseIsAvailable = available
            
            guard available else
            {
                log("This issue occured: \(errorMessage ?? "Flowlist couldn't determine your iCloud account status.")\n\nMake sure your Mac is connected to your iCloud account, then restart Flowlist.\n\nOr: Stop using iCloud via the \"Data\" menu.\n",
                    title: "Whoops, no iCloud?",
                    forUser: true)
                
                action(nil)
                
                return
            }
            
            action(database)
        }
    }
    
    private weak var database: Database?
    
    private var databaseUsageFlag = PersistentFlag(key: "IsUsingDatabase",
                                                   defaultValue: true)
    
    private var databaseIsAvailable: Bool?
    
    // MARK: - File
    
    private func saveStoreItemsToFile()
    {
        guard let root = Store.shared.root else
        {
            log(warning: "Store has no root item.")
            return
        }
        
        file?.save(root)
    }

    private func loadStoreItemsFromFile()
    {
        guard let item = file?.loadItem() else
        {
            log(error: "Couldn't load items from file.")
            return
        }
    
        Store.shared.update(root: item)
    }
    
    private weak var file: ItemFile?
}

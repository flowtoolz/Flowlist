import SwiftObserver

class Storage: Observer
{
    // MARK: - Initialization & Configuration
    
    static let shared = Storage()
    
    private init() { observeStore() }
    
    func configure(with file: ItemFile, database: Database)
    {
        self.file = file
        
        stopObserving(self.database?.messenger)
        
        self.database = database
        
        observeDatabase()
    }
    
    // MARK: - Observe Store and Database
    
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
    
    private func observeStore()
    {
        observe(Store.shared)
        {
            guard case .wasEdited(let edit) = $0 else { return }
            
            //log("applying edit from store to db: \(edit)")
            
            self.database?.apply(edit)
        }
    }
    
    // MARK: - Opting In and Out of iCloud
    
    var isUsingDatabase: Bool
    {
        set
        {
            databaseUsageFlag.value = newValue
            
            // TODO: implement opting in and out of iCloud
        }
        
        get { return databaseUsageFlag.value }
    }
    
    // MARK: - App Life Cycle
    
    func appDidLaunch()
    {
        initializeStoreItems()
    }
    
    func windowLostFocus()
    {
        saveToFile()
    }
    
    func appWillTerminate()
    {
        saveToFile()
    }
    
    // MARK: - Use Cases
    
    private func initializeStoreItems()
    {
        guard isUsingDatabase else
        {
            loadFromFile()
            return
        }
        
        database?.checkAvailability
        {
            available, errorMessage in
            
            self.databaseIsAvailable = available

            guard available else
            {
                log("This issue occured: \(errorMessage ?? "Flowlist couldn't determine your iCloud account status.")\n\nMake sure your Mac is connected to your iCloud account, then restart Flowlist.\n\nOr: Stop using iCloud via the \"Data\" menu.\n",
                    title: "Whoops, no iCloud?",
                    forUser: true)

                self.loadFromFile()

                return
            }

            self.tryToLoadFromDatabase()
        }
    }
    
    private func resetDatabaseWithStoreItems()
    {
        guard let root = Store.shared.root else
        {
            log(warning: "No root in store")
            return
        }
        
        database?.resetItemTree(with: root)
    }
    
    // MARK: - Database
    
    private func tryToLoadFromDatabase()
    {
        database?.fetchItemTree()
        {
            if let root = $0
            {
                Store.shared.update(root: root)
            }
            else
            {
                log(error: "Couldn't fetch item tree. Falling back to file.")
                self.loadFromFile()
            }
        }
    }
    
    private weak var database: Database?
    
    // MARK: - File
    
    private func saveToFile()
    {
        guard let root = Store.shared.root else
        {
            log(warning: "Store has no root item.")
            return
        }
        
        file?.save(root)
    }

    private func loadFromFile()
    {
        guard let item = file?.loadItem() else
        {
            log(error: "Couldn't load items from file.")
            return
        }
    
        Store.shared.update(root: item)
    }
    
    private weak var file: ItemFile?
    
    // MARK: - State
    
    private var databaseUsageFlag = PersistentFlag(key: "IsUsingDatabase",
                                                   defaultValue: true)
    
    private var databaseIsAvailable: Bool?
}

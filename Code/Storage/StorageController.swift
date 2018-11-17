import SwiftObserver

class StorageController<Database: ItemDatabase, File: ItemFile>: Observer
{
    // MARK: - Initialization
    
    init(with file: File, database: Database)
    {
        self.file = file
        
        self.database = database
        
        observe(database)
        {
            guard let edit = $0 else { return }
            
            //log("applying edit from db to store: \(edit)")
            
            Store.shared.apply(edit)
        }
        
        observe(Store.shared)
        {
            guard case .wasEdited(let edit) = $0 else { return }
            
            //log("applying edit from store to db: \(edit)")

            database.apply(edit)
        }
    }
    
    // MARK: - App Life Cycle
    
    func appDidLaunch()
    {
        guard userWantsDatabase.value else
        {
            loadFromFile()
            return
        }
        
        database?.checkAvailability
        {
            available, errorMessage in

            guard available else
            {
                log("This issue did occur: \(errorMessage ?? "Flowlist couldn't determine your iCloud account status.")\n\nMake sure your device is connected to your iCloud account, then restart Flowlist.\n\nOr: Deactivate iCloud integration via the main menu.\n",
                    title: "Whoops, no iCloud?",
                    forUser: true)

                self.loadFromFile()

                return
            }

            self.tryToLoadFromDatabase()
        }

        if let root = Store.shared.root
        {
            database?.resetItemTree(with: root)
        }
    }
    
    func windowLostFocus() { saveToFile() }
    func appWillTerminate() { saveToFile() }
    
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
                log(error: "Couldn't load items from database. Falling back to local file.")
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
            log(warning: "Tried to save items to file but store has no root item.")
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
    
    private weak var file: File?
    
    // MARK: - State
    
    var userWantsDatabase = PersistentFlag(key: "UserWantsDatabase",
                                           defaultValue: true)
}

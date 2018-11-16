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
            
            log("applying edit from db to store: \(edit)")
            
            Store.shared.apply(edit)
        }
        
        observe(Store.shared)
        {
            guard case .wasEdited(let edit) = $0 else { return }
            
            log("applying edit from store to db: \(edit)")

            database.apply(edit)
        }
    }
    
    // MARK: - App Life Cycle
    
    func appDidLaunch()
    {
        print(userWantsICloud.value)
        
        userWantsICloud.value = false
        
//        loadFromFile()
//
//        if let root = Store.shared.root
//        {
//            database?.resetItemTree(with: root)
//        }
        database?.fetchItemTree()
        {
            if let root = $0
            {
                Store.shared.update(root: root)
            }
            else
            {
                self.loadFromFile()
            }
        }
    }
    
    func windowLostFocus() { saveToFile() }
    func appWillTerminate() { saveToFile() }
    
    // MARK: - Database
    
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
    
    var userWantsICloud = PersistentFlag(key: "UserWantsICloud",
                                         defaultValue: true)
}

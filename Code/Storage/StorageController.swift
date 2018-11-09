import SwiftObserver

class StorageController<Database: ItemDatabase, File: ItemFile>: Observer
{
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
    
    func appDidLaunch()
    {
//        loadFromFile()
        
//        if let root = Store.shared.root
//        {
//            database?.createItems(with: root.modifications())
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
    
    func windowLostFocus()
    {
        saveToFile()
    }
    
    func appWillTerminate()
    {
        saveToFile()
    }
    
    // MARK: - Database
    
    private weak var database: Database?
    
    // MARK: - File
    
    private func saveToFile()
    {
        guard let root = Store.shared.root else { return }
        
        file?.save(root)
    }

    private func loadFromFile()
    {
        if let item = file?.loadItem()
        {
            Store.shared.update(root: item)
        }
    }
    
    private weak var file: File?
}

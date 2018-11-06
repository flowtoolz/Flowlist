import SwiftObserver

class StorageController<Database: ItemDatabase, File: ItemFile>: Observer
{
    init(with file: File, database: Database)
    {
        self.file = file
        
        self.database = database
        
        observe(database)
        {
            guard let interaction = $0 else { return }
            
            log("applying interaction from db to store: \(interaction)")
            
            Store.shared.apply(interaction)
        }
        
        observe(Store.shared)
        {
            guard case .wasInteractedWith(let interaction) = $0 else { return }
            
            log("applying interaction from store to db: \(interaction)")
            
            switch interaction
            {
            case .insertItem(let modifications, _):
                database.createItems(with: modifications)
            case .modifyItem(let modification):
                database.modifyItem(with: modification)
            case .removeItemsWithIds(let ids):
                database.deleteItems(with: ids)
            }
        }
    }
    
    func appDidLaunch()
    {
        loadFromFile()
//        database?.fetchItemTree()
//        {
//            if let root = $0
//            {
//                Store.shared.update(root: root)
//            }
//            else
//            {
//                self.loadFromFile()
//            }
//        }
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

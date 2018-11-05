import SwiftObserver

class StorageController <Database: ItemDatabase, Store: PersistableStore>: Observer
{
    init(with database: Database, store: Store)
    {
        self.database = database
        
        observe(database)
        {
            guard let interaction = $0 else { return }
            
            self.store?.apply(interaction)
        }
        
        self.store = store
        
        observe(store)
        {
            guard case .wasInteractedWith(let interaction) = $0 else { return }
            
            switch interaction
            {
            case .insertItem(let modifications, _):
                database.saveItems(with: modifications)
            case .modifyItem(let modification):
                database.saveItem(with: modification)
            case .removeItemsWithIds(let ids):
                database.deleteItems(with: ids)
            }
        }
    }
    
    func appDidLaunch()
    {
//        store?.load()
        database?.fetchItemTree()
        {
            if let root = $0
            {
                self.store?.update(root: root)
            }
            else
            {
                self.store?.load()
            }
        }
    }
    
    func windowLostFocus()
    {
        store?.save()
    }
    
    func appWillTerminate()
    {
        store?.save()
    }
    
    private weak var database: Database?
    private weak var store: Store?
}

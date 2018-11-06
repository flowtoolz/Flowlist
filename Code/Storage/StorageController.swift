import SwiftObserver

class StorageController <Database: ItemDatabase, Store: PersistableStore>: Observer
{
    init(with database: Database, store: Store)
    {
        self.database = database
        
        observe(database)
        {
            guard let interaction = $0 else { return }
            
            log("applying interaction from db to store: \(interaction)")
            
            self.store?.apply(interaction)
        }
        
        self.store = store
        
        observe(store)
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

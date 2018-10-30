import SwiftObserver

class StorageController <Database: ItemDatabase, Store: PersistableStore>: Observer
{
    init(with database: Database, store: Store)
    {
        self.database = database
        self.store = store
        
        observe(database)
        {
            itemEdit in
            
            self.store?.apply(itemEdit)
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

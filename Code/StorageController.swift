import SwiftObserver

class StorageController<Database: ItemDatabase>: Observer
{
    init(with database: Database, store: PersistableStore)
    {
        self.database = database
        self.store = store
        
        observe(database)
        {
            event in
            
            switch event
            {
            case .didNothing: break
            }
        }
    }
    
    func appDidLaunch()
    {
        store?.load()
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
    private weak var store: PersistableStore?
}

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
            case .didModify(let info): break
            case .didCreate(let info): break
            case .didDelete(let id): break
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

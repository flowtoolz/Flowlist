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
            case .didCreate(let info):
                print("created item: id=\(info.data.id) text=<\(info.data.text.value ?? "Untitled")>")
            case .didModify(let info):
                print("modified item: id=\(info.data.id) text=<\(info.data.text.value ?? "Untitled")>")
                print("modified fields: \(info.modified.map({ $0.rawValue }))")
            case .didDelete(let id):
                print("modified item: id=\(id)")
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

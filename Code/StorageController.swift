import SwiftObserver

class StorageController <Database: ItemDatabase, Store: PersistableStore>: Observer
{
    init(with database: Database, store: Store)
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
                print("filled fields: \(info.modified.map({ $0.rawValue }))")
                
            case .didModify(let info):
                print("modified item: id=\(info.data.id) text=<\(info.data.text.value ?? "Untitled")>")
                print("modified fields: \(info.modified.map({ $0.rawValue }))")
            // TODO: be aware that, on modification, icloud always sends root and text, even if they weren't modified...probably has to do with the fact they are indexed
                
                for field in info.modified
                {
                    switch field
                    {
                    case .text:
                        self.store?.update(text: info.data.text.value,
                                           ofItemWithId: info.data.id)
                    case .state:
                        break
                    case .tag:
                        break
                    case .root:
                        break
                    }
                }
                
            case .didDelete(let id):
                print("deleted item: id=\(id)")
            }
        }
    }
    
    func appDidLaunch()
    {
        database?.fetchItemTree()
        {
            root in

            if let root = root
            {
                self.store?.set(newRoot: root)
            }
        }
    }
    
    func windowLostFocus()
    {
        //store?.save()
    }
    
    func appWillTerminate()
    {
        //store?.save()
    }
    
    private weak var database: Database?
    private weak var store: Store?
}

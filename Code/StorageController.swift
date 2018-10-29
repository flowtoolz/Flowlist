import SwiftObserver

class StorageController<Database: ItemDatabase>: Observer
{
    init(with database: Database)
    {
        self.database = database
        
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
        // TODO: the storage controller coordinates the logic of storage and syncronization but it should not depend on Foundation or AppKit. The Store's load and save functions introduce these unwanted dependencies. Fix that!
        store.load()
    }
    
    func windowLostFocus()
    {
        store.save()
    }
    
    func appWillTerminate()
    {
        store.save()
    }
    
    private weak var database: Database?
}

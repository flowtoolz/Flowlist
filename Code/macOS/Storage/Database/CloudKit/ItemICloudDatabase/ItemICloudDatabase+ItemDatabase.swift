import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase: ItemDatabase
{
    func reset(root: Item?) -> Promise<Void>
    {
        return firstly
        {
            self.deleteRecords()
        }
        .then(on: globalQ)
        {
            () -> Promise<Void> in
            
            guard let root = root else { return Promise() }
            
            return self.save(root.makeRecordsRecursively())
        }
    }
    
    func apply(_ edit: Edit) -> Promise<Void>
    {
        guard didEnsureAccess else
        {
            let errorMessage = "Tried to edit iCloud database while it hasn't yet ensured access."
            return Promise(error: ReadableError.message(errorMessage))
        }
        
        switch edit
        {
        case .updateItems(let records): return save(records)
        case .removeItems(let ids): return removeRecords(with: ids)
        }
    }
  
    func fetchRecords() -> Promise<[Record]>
    {
        return firstly
        {
            fetchItemCKRecords()
        }
        .map(on: globalQ)
        {
            $0.map(Record.init)
        }
    }
}

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
        .then(on: backgroundQ)
        {
            () -> Promise<Void> in
            
            guard let root = root else { return Promise() }
            
            let ckRecords = root.array.map
            {
                CKRecord(record: $0.makeRecord())
            }
            
            return self.save(ckRecords)
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
        case .updateItems(let records): return update(records)
        case .removeItems(let ids): return removeRecords(with: ids)
        }
    }
  
    func fetchRecords() -> Promise<[Record]>
    {
        return firstly
        {
            fetchItemCKRecords()
        }
        .map(on: backgroundQ)
        {
            $0.map(Record.init)
        }
    }
}

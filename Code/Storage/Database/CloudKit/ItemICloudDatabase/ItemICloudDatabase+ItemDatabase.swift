import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase: ItemDatabase
{
    func reset(root: Item) -> Promise<Void>
    {
        return firstly
        {
            self.deleteRecords()
        }
        .then(on: backgroundQ)
        {
            () -> Promise<Void> in
            
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
            return Promise(error: StorageError.message(errorMessage))
        }
        
        switch edit
        {
        case .updateItems(let records): return update(records)
        case .removeItems(let ids): return removeRecords(with: ids)
        }
    }
  
    func fetchRecords() -> Promise<[Record]>
    {
        return Promise<[Record]>
        {
            resolver in
            
            firstly
            {
                fetchItemCKRecords()
            }
            .map(on: backgroundQ)
            {
                $0.map(Record.init)
            }
            .done(on: backgroundQ, resolver.fulfill).catch(on: backgroundQ)
            {
                resolver.reject($0.storageError)
            }
        }
    }
}

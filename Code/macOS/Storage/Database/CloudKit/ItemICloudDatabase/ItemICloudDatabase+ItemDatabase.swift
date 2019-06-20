import CloudKit
import SwiftObserver
import SwiftyToolz
import PromiseKit

extension ItemICloudDatabase: ItemDatabase
{
    func reset(root: Item?) -> Promise<Void>
    {
        return firstly
        {
            // TODO: enforce deletion here via parameter force: Bool and internally adjusting save policy. Or better: add force parameter to this func. also return ItemDatabaseModificationResult instead of void. pass force parameter to both following sub routines: delete and save. thereby avoid problem of ignoring conflicting records on delete and save... move that problem outside
            self.deleteRecords()
        }
        .then(on: queue)
        {
            modificationResult -> Promise<Void> in
            
            guard let root = root else { return Promise() }
            
            switch modificationResult
            {
            case .success:
                return self.save(Record.makeRecordsRecursively(for: root)).map { _ in }
            case .conflictingRecords(_):
                let message = "Could not reset iCloud database because there are conflicts. Resetting the db should force deletion!"
                log(error: message)
                return Promise(error: ReadableError.message(message))
            }
        }
    }
    
    func apply(_ edit: Edit) -> Promise<ItemDatabaseModificationResult>
    {
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
        .map(on: queue)
        {
            $0.map { $0.makeItemRecord() }
        }
    }
}

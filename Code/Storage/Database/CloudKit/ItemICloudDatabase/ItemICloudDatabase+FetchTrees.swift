import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase
{
    func fetchTrees() -> Promise<[Item]>
    {
        return firstly
        {
            fetchAllItemRecords()
        }
        .map
        {
            (records: [CKRecord]) -> [Item] in
            
            // TODO: get all possible roots instead of assuming there's always exactly one
            guard let root = Item(records: records) else { return [] }
            
            return [root]
        }
    }
    
    private func fetchAllItemRecords() -> Promise<[CKRecord]>
    {
        return firstly { fetchAllUpdates() }.map { $0.changedRecords }
    }
}

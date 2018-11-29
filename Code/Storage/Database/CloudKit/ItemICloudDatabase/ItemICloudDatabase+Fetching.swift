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
    
    func fetchUpdates() -> Promise<[Edit]>
    {
        return firstly
        {
            self.fetchNewUpdates()
        }
        .map
        {
            (result: ChangeFetch.Result) -> [Edit] in
            
            var edits = [Edit]()
            
            if result.idsOfDeletedRecords.count > 0
            {
                let ids = result.idsOfDeletedRecords.map { $0.recordName }
                edits.append(.removeItems(withIDs: ids))
            }
            
            if result.changedRecords.count > 0
            {
                let mods = result.changedRecords.compactMap
                {
                    $0.modification
                }
                
                edits.append(.updateItems(withModifications: mods))
            }
            
            return edits
        }
    }
}
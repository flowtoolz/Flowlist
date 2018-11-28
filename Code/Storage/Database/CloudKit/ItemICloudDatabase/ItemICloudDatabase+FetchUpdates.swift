import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase
{
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

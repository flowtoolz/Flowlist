import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase
{
    func fetchUpdates(handleResult: @escaping UpdateHandler)
    {
        firstly {
            updateServerChangeToken(zoneID: CKRecordZone.ID.item,
                                    oldToken: serverChangeToken)
        }.done { result in
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
            
            handleResult(edits)
        }.catch {
            log($0)
            handleResult(nil)
        }
    }
}

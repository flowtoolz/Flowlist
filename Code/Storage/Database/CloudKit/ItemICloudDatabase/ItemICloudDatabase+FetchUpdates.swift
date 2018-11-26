import CloudKit
import SwiftObserver

extension ItemICloudDatabase
{
    func fetchUpdates(handleResult: @escaping UpdateHandler)
    {
        updateServerChangeToken(zoneID: CKRecordZone.ID.item,
                                oldToken: serverChangeToken)
        {
            guard let result = $0 else
            {
                log(error: "Could not fetch updates.")
                handleResult(nil)
                return
            }
            
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
        }
    }
}

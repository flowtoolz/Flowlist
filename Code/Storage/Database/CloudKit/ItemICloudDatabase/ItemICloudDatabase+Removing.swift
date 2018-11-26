import CloudKit
import SwiftObserver

extension ItemICloudDatabase
{
    func removeItems(with ids: [String])
    {
        let recordIDs = ids.map { CKRecord.ID(itemID: $0) }
        
        deleteRecords(withIDs: recordIDs)
        {
            guard $0 else
            {
                log(error: "Couldn't delete records.")
                return
            }
        }
    }
    
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    {
        deleteRecords(ofType: CKRecord.itemType,
                      inZone: CKRecordZone.ID.item,
                      handleSuccess: handleSuccess)
    }
}

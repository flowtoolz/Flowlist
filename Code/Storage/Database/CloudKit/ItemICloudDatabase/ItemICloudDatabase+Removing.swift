import CloudKit
import SwiftObserver

extension ItemICloudDatabase
{
    func removeItems(with ids: [String],
                     handleSuccess: @escaping (Bool) -> Void)
    {
        let recordIDs = ids.map { CKRecord.ID(itemID: $0) }
        
        deleteRecords(withIDs: recordIDs,
                      handleSuccess: handleSuccess)
    }
    
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    {
        deleteRecords(ofType: CKRecord.itemType,
                      inZone: CKRecordZone.ID.item,
                      handleSuccess: handleSuccess)
    }
}

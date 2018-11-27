import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase
{
    func removeItems(with ids: [String],
                     handleSuccess: @escaping (Bool) -> Void)
    {
        let recordIDs = ids.map { CKRecord.ID(itemID: $0) }
        
        firstly {
            deleteRecords(withIDs: recordIDs)
        }.done {
            handleSuccess(true)
        }.catch {
            log($0)
            handleSuccess(false)
        }
    }
    
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    {
        firstly {
            deleteRecords(ofType: CKRecord.itemType,
                          inZone: CKRecordZone.ID.item)
        }.done {
            handleSuccess(true)
        }.catch {
            log($0)
            handleSuccess(false)
        }
    }
}

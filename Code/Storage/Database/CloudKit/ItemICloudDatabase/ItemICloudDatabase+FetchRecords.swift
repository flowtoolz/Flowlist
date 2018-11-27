import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase
{
    func fetchAllItemRecords(handleResult: @escaping ([CKRecord]?) -> Void)
    {
        updateServerChangeToken(zoneID: CKRecordZone.ID.item,
                                oldToken: nil)
        {
            result in
            
            guard let result = result else
            {
                log(error: "Fetching changes failed.")
                handleResult(nil)
                return
            }
            
            handleResult(result.changedRecords)
        }
    }
    
    func fetchSubitemRecords(of itemRecord: CKRecord,
                             handleResult: @escaping ([CKRecord]?) -> Void)
    {
        guard itemRecord.isItem else { return }
        
        fetchSubitemRecords(withSuperItemID: itemRecord.recordID,
                            handleResult: handleResult)
    }
    
    func fetchSubitemRecords(withSuperItemID id: CKRecord.ID,
                             handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        fetchItemRecords(predicate, handleResult: handleResult)
    }
    
    func fetchItemRecords(_ predicate: NSPredicate,
                          handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let query = CKQuery(recordType: CKRecord.itemType,
                            predicate: predicate)
        
        firstly {
            fetchRecords(with: query, inZone: CKRecordZone.ID.item)
        }.done {
            handleResult($0)
        }.catch {
            log($0)
            handleResult(nil)
        }
    }
}

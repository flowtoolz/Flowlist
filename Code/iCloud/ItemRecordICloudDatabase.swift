import CloudKit
import SwiftObserver
import SwiftyToolz

let database = ItemRecordICloudDatabase()

class ItemRecordICloudDatabase: ICloudDatabase, ItemDatabase
{
    fileprivate override init() {}
    
    // MARK: - Observe Item Records
    
    override func didCreateRecord(with id: CKRecordID,
                                  notification: CKQueryNotification)
    {
        if !hasAllNewFields(notification)
        {
            // TODO: fetch record
        }
        
        // TODO: send update to someone who will adjust items
    }
    
    override func didModifyRecord(with id: CKRecordID,
                                  notification: CKQueryNotification)
    {
        if !hasAllNewFields(notification)
        {
            // TODO: fetch record
        }
        
        // TODO: send update to someone who will adjust items
    }
    
    override func didDeleteRecord(with id: CKRecordID)
    {
        // TODO: send update to someone who will adjust items
    }
    
    private func hasAllNewFields(_ notification: CKQueryNotification) -> Bool
    {
        if !notification.isPruned { return true }
        
        return notification.recordFields?.count == itemRecordTags.count
    }
    
    func createItemRecordSubscription()
    {
        let alertKey = "Items where changed in iCloud."
        
        createSubscription(forRecordType: "Item",
                           desiredTags: itemRecordTags,
                           alertLocalizationKey: alertKey)
    }
    
    private var itemRecordTags: [String]
    {
        return ["text", "tag", "state", "superItem"]
    }
    
    // MARK: - Fetch Item Records
    
    func fetchItemRecords(handleResult: @escaping ([CKRecord]?) -> Void)
    {
        fetchItemRecords(with: NSPredicate(value: true),
                         handleResult: handleResult)
    }
    
    func fetchSubitemRecords(of itemRecord: CKRecord,
                             handleResult: @escaping ([CKRecord]?) -> Void)
    {
        guard itemRecord.recordType == "Item" else { return }
        
        fetchSubitemRecords(withSuperItemID: itemRecord.recordID,
                            handleResult: handleResult)
    }
    
    func fetchSubitemRecords(withSuperItemID id: CKRecordID,
                             handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        fetchItemRecords(with: predicate, handleResult: handleResult)
    }
    
    func fetchItemRecords(with predicate: NSPredicate,
                          handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let query = CKQuery(recordType: "Item", predicate: predicate)
        
        fetchRecords(with: query, handleResult: handleResult)
    }
    
    // MARK: - Observability
    
    var latestUpdate: ItemDatabaseEvent { return .didNothing }
}

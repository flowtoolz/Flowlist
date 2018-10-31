import CloudKit
import SwiftObserver
import SwiftyToolz

let database = ItemICloudDatabase()

class ItemICloudDatabase: ICloudDatabase, Observable
{
    fileprivate override init() {}
    
    // MARK: - Observe Item Records
    
    override func didCreateRecord(with id: CKRecord.ID,
                                  notification: CKQueryNotification)
    {
        guard let fields = allNewFields(notification) else
        {
            fetchRecord(with: id)
            {
                newRecord in
                
                guard let record = newRecord else
                {
                    log(error: "Fetched new record is nil.")
                    return
                }
                
                if let modification = record.modification
                {
                    self.send(.create(modification))
                }
            }
            
            return
        }
        
        if let modification = id.modification(fromNotificationFields: fields)
        {
            send(.create(modification))
        }
    }
    
    override func didModifyRecord(with id: CKRecord.ID,
                                  notification: CKQueryNotification)
    {
        guard let fields = allNewFields(notification) else
        {
            fetchRecord(with: id)
            {
                modifiedRecord in
                
                guard let record = modifiedRecord else
                {
                    log(error: "Fetched modified record is nil.")
                    return
                }
                
                guard let modification = record.modification else { return }
                
                self.send(.modify(modification))
            }
            
            return
        }
        
        if let modification = id.modification(fromNotificationFields: fields)
        {
            send(.modify(modification))
        }
    }
    
    override func didDeleteRecord(with id: CKRecord.ID)
    {
        send(.delete(id: id.recordName))
    }
    
    private func allNewFields(_ notification: CKQueryNotification) -> JSON?
    {
        guard let fields = notification.recordFields else { return nil }
        
        if !notification.isPruned || fields.count == itemFieldNames.count
        {
            return fields
        }
        
        return nil
    }
    
    @available(OSX 10.12, *)
    func createItemRecordSubscription()
    {
        let alertKey = "Items where changed in iCloud."
        
        createSubscription(forRecordType: CKRecord.itemType,
                           desiredTags: itemFieldNames,
                           alertLocalizationKey: alertKey)
    }
    
    private let itemFieldNames = CKRecord.fieldNames
    
    // MARK: - Fetch Item Records
    
    func fetchItemRecords(handleResult: @escaping ([CKRecord]?) -> Void)
    {
        fetchItemRecords(with: NSPredicate(value: true),
                         handleResult: handleResult)
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
        
        fetchItemRecords(with: predicate, handleResult: handleResult)
    }
    
    func fetchItemRecords(with predicate: NSPredicate,
                          handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let query = CKQuery(recordType: CKRecord.itemType,
                            predicate: predicate)
        
        fetchRecords(with: query, handleResult: handleResult)
    }
    
    // MARK: - Observability
    
    var latestUpdate = Item.Interaction.none
}

import CloudKit
import SwiftObserver
import SwiftyToolz

let database = ItemICloudDatabase()

class ItemICloudDatabase: ICloudDatabase, Observable
{
    fileprivate override init() {}
    
    // MARK: - Observe Item Records
    
    override func didCreateRecord(with id: CKRecordID,
                                  notification: CKQueryNotification)
    {
        guard let recordFields = allNewFields(notification) else
        {
            fetchRecord(with: id)
            {
                newRecord in
                
                guard let record = newRecord else
                {
                    log(error: "Fetched new record is nil.")
                    return
                }
                
                guard let edit = Item.edit(from: record) else
                {
                    log(error: "Could not create update info for new record.")
                    return
                }
                
                self.send(.didCreate(edit))
            }
            
            return
        }
        
        guard let edit = Item.edit(with: id,
                                   notificationFields: recordFields)
        else
        {
            log(error: "Could not create update info for new record with id \(id.recordName) and fields \(recordFields.debugDescription).")
            return
        }
        
        send(.didCreate(edit))
    }
    
    override func didModifyRecord(with id: CKRecordID,
                                  notification: CKQueryNotification)
    {
        guard let recordFields = allNewFields(notification) else
        {
            fetchRecord(with: id)
            {
                modifiedRecord in
                
                guard let record = modifiedRecord else
                {
                    log(error: "Fetched modified record is nil.")
                    return
                }
                
                guard let edit = Item.edit(from: record) else
                {
                    log(error: "Could not create update info for modified record.")
                    return
                }
                
                self.send(.didModify(edit))
            }
            
            return
        }
        
        guard let edit = Item.edit(with: id,
                                   notificationFields: recordFields)
        else
        {
            log(error: "Could not create update info for modified record with id \(id.recordName) and fields \(recordFields.debugDescription).")
            return
        }
        
        send(.didModify(edit))
    }
    
    override func didDeleteRecord(with id: CKRecordID)
    {
        send(.didDelete(id: id.recordName))
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
    
    func fetchSubitemRecords(withSuperItemID id: CKRecordID,
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
    
    var latestUpdate = Item.Operation.didNothing
}

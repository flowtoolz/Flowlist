import CloudKit
import SwiftObserver
import SwiftyToolz

extension Tree where Data == ItemData
{
    var ckRecord: CKRecord?
    {
        return ICloud.createItemRecord(from: self)
    }
}

class ICloud
{
    // MARK: - Testing
    
    func test()
    {
        print("TESTING ICLOUD")
        
        container.accountStatus
        {
            status, error in
            
            if let error = error
            {
                print("An error occured requesting the iCloud account status: \(error.localizedDescription)")
                return
            }
            
            switch status
            {
            case .couldNotDetermine:
                print("Could not determine iCloud account status.")
            case .available:
                print("iCloud account is available.")
            case .restricted:
                print("iCloud account is restricted.")
            case .noAccount:
                print("This device is not connected to an iCloud account.")
            }
        }
    }
    
    // MARK: - Observe Changes in iCloud

    func didReceiveRemoteNotification(with userInfo: [String : Any])
    {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        guard notification.notificationType == .query,
            let queryNotification = notification as? CKQueryNotification
        else
        {
            return
        }
        
        print("received query notification: \(queryNotification.debugDescription)")
    
        let recordName = queryNotification.recordID?.recordName ?? "nil"
        
        switch queryNotification.queryNotificationReason
        {
        case .recordCreated:
            print("did create record: <\(recordName)>")
            
        case .recordUpdated:
            print("did change record: <\(recordName)>")
            
        case .recordDeleted:
            print("did delete record: <\(recordName)>")
        }
    }
    
    private func setupSubscription()
    {
        let options: CKSubscriptionOptions =
        [
            .firesOnRecordUpdate,
            .firesOnRecordCreation,
            .firesOnRecordDeletion
        ]
        
        let subscription = CKSubscription(recordType: "Item",
                                          predicate: NSPredicate(value: true),
                                          options: options)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertLocalizationKey = "Items Changed"
        notificationInfo.shouldBadge = false
        
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription)
        {
            savedSubscription, error in
            
            if let error = error
            {
                print("Could not save iCloud subscription. Error: \(error.localizedDescription)")
                return
            }
            
            print("Saved iCloud subscription: \(savedSubscription.debugDescription)")
        }
    }
    
    // MARK: - Convert between Item & Record
    
    /**
     sets the item root with the given closure. does NOT insert the item into the root.
     **/
    static func createItem(from itemRecord: CKRecord,
                           rootWithUuid: (String) -> Item?) -> Item?
    {
        guard itemRecord.recordType == "Item" else
        {
            return nil
        }
        
        let data = ItemData(id: itemRecord.recordID.recordName)
        
        data.title <- itemRecord["text"]
        
        if let stateInt: Int = itemRecord["state"]
        {
            data.state <- ItemData.State(rawValue: stateInt)
        }
        
        if let tagInt: Int = itemRecord["tag"]
        {
            data.tag <- ItemData.Tag(rawValue: tagInt)
        }
        
        let item = Item(data: data)
        
        if let rootReference: CKReference = itemRecord["superItem"]
        {
            let rootUuid = rootReference.recordID.recordName
            
            item.root = rootWithUuid(rootUuid)
        }
        
        return item
    }
    
    static func createItemRecord(from item: Item) -> CKRecord?
    {
        guard let data = item.data else { return nil }
        
        let recordId = CKRecordID(recordName: data.id)
        let record = CKRecord(recordType: "Item", recordID: recordId)
        
        record["text"] = item.title
        record["state"] = data.state.value?.rawValue
        record["tag"] = data.tag.value?.rawValue
        
        if let rootData = item.root?.data
        {
            let superItemId = CKRecordID(recordName: rootData.id)
            record["superItem"] = ownerReference(to: superItemId)
        }
        
        return record
    }
    
    // MARK: - Fetch Item Records
    
    private func fetchItemRecords(resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        fetchItemRecords(with: NSPredicate(value: true),
                         resultHandler: resultHandler)
    }
    
    private func fetchSubitemRecords(of itemRecord: CKRecord,
                                     resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        guard itemRecord.recordType == "Item" else { return }
        
        fetchSubitemRecords(withSuperItemID: itemRecord.recordID,
                            resultHandler: resultHandler)
    }
    
    private func fetchSubitemRecords(withSuperItemID id: CKRecordID,
                                     resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        fetchItemRecords(with: predicate, resultHandler: resultHandler)
    }
    
    private func fetchItemRecords(with predicate: NSPredicate,
                                  resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        let query = CKQuery(recordType: "Item", predicate: predicate)
        
        fetchRecords(with: query, resultHandler: resultHandler)
    }
    
    // MARK: - iCloud
    
    private func fetchRecords(with query: CKQuery,
                              resultHandler: @escaping ([CKRecord]?) -> Void)
    {
        database.perform(query, inZoneWith: .default)
        {
            records, error in
            
            if let error = error
            {
                log(error: "Could not fetch iCloud records. Error: \(error.localizedDescription)")
                resultHandler(nil)
                return
            }
            
            if records == nil
            {
                log(error: "Could not fetch iCloud records. The result array is nil.")
            }
            
            resultHandler(records)
        }
    }
    
    
    private func save(_ record: CKRecord,
                      resultHandler: @escaping (CKRecord?) -> Void)
    {
        database.save(record)
        {
            savedRecord, error in
            
            if let error = error
            {
                log(error: "Could not save iCloud record. Error: \(error.localizedDescription)")
                resultHandler(nil)
                return
            }
            
            if savedRecord == nil
            {
                log(error: "Could not save iCloud record. The result record is nil.")
            }
            
            resultHandler(savedRecord)
        }
    }
    
    private static func ownerReference(to id: CKRecordID) -> CKReference
    {
        return CKReference(recordID: id, action: .deleteSelf)
    }
    
    private var database: CKDatabase
    {
        return container.privateCloudDatabase
    }
    
    private var container: CKContainer
    {
        return CKContainer.default()
    }
}

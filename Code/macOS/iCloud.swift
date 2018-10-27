import CloudKit
import SwiftyToolz

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
        print("received push: \(userInfo.debugDescription)")
        
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        guard notification.notificationType == .query,
            let queryNotification = notification as? CKQueryNotification
        else
        {
            return
        }
    
        let recordName = queryNotification.recordID?.recordName ?? "nil"
        
        switch queryNotification.queryNotificationReason
        {
        case .recordCreated:
            print("did create record: <\(recordName)>")
            
        case .recordUpdated:
            let changedFields = queryNotification.recordFields
            
            print("did change record: <\(recordName)> in fields: \(changedFields?.debugDescription ?? "nil")")
            
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
    
    // MARK: - Create Item Record
    
    private func createItemRecord(with text: String) -> CKRecord
    {
        let recordId = CKRecordID(recordName: "id \(Int.random(max: Int.max))")
        
        let record = CKRecord(recordType: "Item", recordID: recordId)
        
        record["text"] = text
        
        return record
    }
    
    // MARK: - Fetch Item Records
    
    private func fetchItemecords(resultHandler: @escaping ([CKRecord]?) -> Void)
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
    
    private func createReference(toOwner owner: CKRecord) -> CKReference
    {
        return CKReference(recordID: owner.recordID, action: .deleteSelf)
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

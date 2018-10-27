import CloudKit

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
                //self.setupSubscriptions()
            case .restricted:
                print("iCloud account is restricted.")
            case .noAccount:
                print("This device is not connected to an iCloud account.")
            }
        }
    }
    
    // MARK: - Observe Changes in iCloud
    
    private func setupSubscriptions()
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
    
    private func fetchAllItems()
    {
        fetchItemRecords(with: NSPredicate(value: true))
    }
    
    private func fetchSubitemRecords(of itemRecord: CKRecord)
    {
        guard itemRecord.recordType == "Item" else { return }
        
        fetchSubitemRecords(withSuperItemID: itemRecord.recordID)
    }
    
    private func fetchSubitemRecords(withSuperItemID id: CKRecordID)
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        fetchItemRecords(with: predicate)
    }
    
    private func fetchItemRecords(with predicate: NSPredicate)
    {
        let query = CKQuery(recordType: "Item", predicate: predicate)
        
        database.perform(query, inZoneWith: .default)
        {
            records, error in
            
            if let error = error
            {
                print("Could not fetch Item iCloud records. Error: \(error.localizedDescription)")
                return
            }
            
            guard let records = records else { return }
            
            for record in records
            {
                print("fetched record name: \(record.recordID.recordName)")
            }
        }
    }
    
    // MARK: - iCloud
    
    private func save(_ record: CKRecord)
    {
        database.save(record)
        {
            savedRecord, error in
            
            print("saved record: \(savedRecord.debugDescription)")
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

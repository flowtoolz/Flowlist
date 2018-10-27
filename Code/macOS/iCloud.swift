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
//                self.fetchAndModifyTestRecord()
                let rootItemId = CKRecordID(recordName: "test")
                self.fetchSubitemRecords(withSuperItemID: rootItemId)
            case .restricted:
                print("iCloud account is restricted.")
            case .noAccount:
                print("This device is not connected to an iCloud account.")
            }
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
        let ownerId = owner.recordID
        
        return CKReference(recordID: ownerId, action: .deleteSelf)
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

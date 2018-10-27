import CloudKit

class ICloud
{
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
                self.fetchAndModifyTestRecord()
            case .restricted:
                print("iCloud account is restricted.")
            case .noAccount:
                print("This device is not connected to an iCloud account.")
            }
        }
    }
    
    private func fetchAndModifyTestRecord()
    {
        let recordId = CKRecordID(recordName: "test3")
    
        database.fetch(withRecordID: recordId)
        {
            record, error in
            
            if let error = error
            {
                print("An error occured fetching iCloud record: \(error.localizedDescription)")
                return
            }
            
            guard let record = record else { return }
            
            print("fetched record: \(record.debugDescription)")
            
            print("all keys: \(record.allKeys())")
            
            let text: String = record["text"] ?? "nil"
            
            record["text"] = text + " modified"
            
            self.save(record)
        }
    }
    
    private func createRecord(with text: String)
    {
        let recordId = CKRecordID(recordName: "id \(Int.random(max: Int.max))" + text)
        
        let record = CKRecord(recordType: "Item", recordID: recordId)
        
        record["text"] = text
        
        save(record)
    }
    
    private func save(_ record: CKRecord)
    {
        database.save(record)
        {
            savedRecord, error in
            
            print("saved record: \(savedRecord.debugDescription)")
        }
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

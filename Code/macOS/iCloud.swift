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
                self.fetchTestRecord()
//                self.saveTestRecord()
            case .restricted:
                print("iCloud account is restricted.")
            case .noAccount:
                print("This device is not connected to an iCloud account.")
            }
        }
    }
    
    private func fetchTestRecord()
    {
        let database = container.privateCloudDatabase
        
        let recordId = CKRecordID(recordName: "test3")
        
        database.fetch(withRecordID: recordId)
        {
            fetchedRecord, error in
            
            if let error = error
            {
                print("An error occured fetching iCloud record: \(error.localizedDescription)")
                return
            }
            
            print("fetched record: \(fetchedRecord?.debugDescription)")
            
            print("all keys: \(fetchedRecord?.allKeys())")
        }
    }
    
    private func saveTestRecord()
    {
        let recordId = CKRecordID(recordName: "test3")
        
        let record = CKRecord(recordType: "Item", recordID: recordId)
        
        record["text"] = "this is a test text"
        
        let database = container.privateCloudDatabase
        
        database.save(record)
        {
            savedRecord, error in
            
            print(savedRecord.debugDescription)
        }
    }
    
    private var container: CKContainer
    {
        return CKContainer.default()
    }
}

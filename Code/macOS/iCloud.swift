import CloudKit

class ICloud
{
    func test()
    {
        print("TESTING ICLOUD")
        
        let container = CKContainer.default()
        
        let database = container.privateCloudDatabase
        
        let recordId = CKRecordID(recordName: "test")
        
        let record = CKRecord(recordType: "test type", recordID: recordId)
        
        database.save(record)
        {
            (savedRecord, error) in
            
            // handle response
        }
    }
}

import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    public func perform(_ query: CKQuery,
                        inZoneWith zoneID: CKRecordZone.ID? = nil) -> Promise<[CKRecord]>
    {
        return Promise
        {
            resolver in
            
            perform(query, inZoneWith: zoneID)
            {
                records, error in
                
                if let error = error
                {
                    log(error: error.localizedDescription)
                }
                
                resolver.resolve(records, error?.storageError)
            }
        }
    }
    
    public func fetchUserCKRecord() -> Promise<CKRecord>
    {
        return firstly
        {
            CKContainer.default().fetchUserCKRecordID()
        }
        .then(on: DispatchQueue.global(qos: .userInitiated))
        {
            self.fetchCKRecord(withID: $0)
        }
    }
    
    public func fetchCKRecord(withID recordID: CKRecord.ID) -> Promise<CKRecord>
    {
        return Promise
        {
            resolver in
            
            fetch(withRecordID: recordID)
            {
                record, error in
                
                if let error = error
                {
                    log(error: error.localizedDescription)
                }
                
                resolver.resolve(record, error?.storageError)
            }
        }
    }
}

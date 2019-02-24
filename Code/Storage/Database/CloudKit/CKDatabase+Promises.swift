import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    /// Searches the specified zone asynchronously for records that match the query parameters.
    public func performQuery(_ query: CKQuery,
                             inZoneWith zoneID: CKRecordZone.ID? = nil) -> Promise<[CKRecord]>
    {
        return Promise
        {
            perform(query,
                    inZoneWith: zoneID,
                    completionHandler: $0.resolve)
        }
    }
    
    public func requestUserRecord() -> Promise<CKRecord>
    {
        return firstly
        {
            CKContainer.default().requestUserRecordID()
        }
        .then(on: DispatchQueue.global(qos: .background))
        {
            return self.requestRecord(withID: $0)
        }
    }
    
    public func requestRecord(withID recordID: CKRecord.ID) -> Promise<CKRecord>
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
                
                resolver.resolve(record, error)
            }
        }
    }
}

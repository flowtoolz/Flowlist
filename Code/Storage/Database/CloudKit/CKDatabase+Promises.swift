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
                
                resolver.resolve(records, error)
            }
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

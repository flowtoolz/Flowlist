import CloudKit
import PromiseKit
import SwiftyToolz

extension CKContainer
{
    public func requestUserRecordID() -> Promise<CKRecord.ID>
    {
        return Promise
        {
            resolver in
            
            fetchUserRecordID
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
    
    public func requestAccountStatus() -> Promise<CKAccountStatus>
    {
        return Promise
        {
            resolver in
            
            accountStatus
            {
                status, error in
                
                if let error = error
                {
                    log(error: error.localizedDescription)
                }
                
                resolver.resolve(status, error)
            }
        }
    }
}

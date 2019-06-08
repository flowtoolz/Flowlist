import CloudKit
import PromiseKit
import SwiftyToolz

extension CKContainer
{
    public func fetchUserCKRecordID() -> Promise<CKRecord.ID>
    {
        return Promise
        {
            resolver in
            
            fetchUserRecordID
            {
                id, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                }
                
                resolver.resolve(id, error?.ckReadable)
            }
        }
    }
    
    public func fetchAccountStatus() -> Promise<CKAccountStatus>
    {
        return Promise
        {
            resolver in
            
            accountStatus
            {
                status, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                }
                
                resolver.resolve(status, error?.ckReadable)
            }
        }
    }
}

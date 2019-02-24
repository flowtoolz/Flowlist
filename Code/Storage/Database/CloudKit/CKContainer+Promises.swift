import CloudKit
import PromiseKit
import SwiftyToolz

extension CKContainer
{
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

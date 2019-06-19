import CloudKit
import PromiseKit
import SwiftyToolz

extension CKContainer
{    
    func fetchAccountStatus() -> Promise<CKAccountStatus>
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

import CloudKit
import PromiseKit
import SwiftyToolz

extension CKContainer
{
    func ensureAccountAccess() -> Promise<Void>
    {
        return firstly
        {
            fetchAccountStatus()
        }
        .map(on: iCloudQueue)
        {
            status -> Void in
            
            let errorMessage: String? =
            {
                switch status
                {
                case .couldNotDetermine: return "Could not determine iCloud account status."
                case .available: return nil
                case .restricted: return "iCloud account is restricted."
                case .noAccount: return "Cannot access the iCloud account."
                @unknown default: return "Unknown account status."
                }
            }()
            
            if let errorMessage = errorMessage
            {
                log(error: errorMessage)
                throw ReadableError.message(errorMessage)
            }
        }
    }
    
    private func fetchAccountStatus() -> Promise<CKAccountStatus>
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

let iCloudQueue = DispatchQueue(label: "iCloud", qos: .userInitiated)

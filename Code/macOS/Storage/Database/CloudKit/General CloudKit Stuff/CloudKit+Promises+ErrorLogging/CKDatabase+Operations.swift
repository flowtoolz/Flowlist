import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    func perform(_ operation: CKDatabaseOperation)
    {
        operation.queuePriority = .high
        operation.qualityOfService = .userInitiated
        add(operation)
    }
    
    func setTimeout<T>(of seconds: Double = CKDatabase.timeoutAfterSeconds,
                       on operation: CKDatabaseOperation,
                       or resolver: Resolver<T>)
    {
        if #available(OSX 10.13, *)
        {
            operation.configuration.timeoutIntervalForRequest = seconds
            operation.configuration.timeoutIntervalForResource = seconds
        }
        else
        {
            after(.seconds(Int(seconds))).done
            {
                resolver.reject(ReadableError.message("iCloud database operation didn't respond and was cancelled after \(seconds) seconds."))
            }
        }
    }
    
    #if DEBUG
    static let timeoutAfterSeconds: Double = 5
    #else
    static let timeoutAfterSeconds: Double = 20
    #endif
    
    // TODO: Retry requests if error has ckShouldRetry, wait ckError.retryAfterSeconds ...
    
    func retry(after seconds: Double, action: @escaping () -> Void)
    {
        let retryTime = DispatchTime.now() + seconds
        
        queue.asyncAfter(deadline: retryTime, execute: action)
    }
    
    var queue: DispatchQueue { return iCloudQueue }
}

private let iCloudQueue = DispatchQueue(label: "iCloud", qos: .userInitiated)

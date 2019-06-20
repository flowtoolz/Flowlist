import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    func modify(with operation: CKModification) -> Promise<CKModification.Result>
    {
        if (operation.recordIDsToDelete?.count ?? 0) +
           (operation.recordsToSave?.count ?? 0) > CKModification.maxBatchSize
        {
            let message = "Too many items in CKModifyRecordsOperation."
            log(error: message)
            return Promise(error: ReadableError.message(message))
        }
        
        // TODO: since .serverRecordChanged signifies one conflicting record it's probably being reported here on a per record basis. if that is so and a .serverRecordChanged occurs here, then what happens in the modifyRecordsCompletionBlock?
        operation.perRecordCompletionBlock =
        {
            if let error = $1
            {
                log(error: error.ckReadable.message)
            }
        }
        
        return Promise
        {
            resolver in
            
            setTimeout(on: operation, or: resolver)
            
            operation.modifyRecordsCompletionBlock =
            {
                _, _, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                    
                    if let ckError = error.ckError
                    {
                        if case .serverRecordChanged = ckError.code
                        {
                            // TODO: retrieve conflicting CKRecords from ckError and propagate them to Storage where they must arrive as type Record
                            
 // https://developer.apple.com/documentation/cloudkit/ckerror/code/serverrecordchanged
                            return resolver.fulfill(.conflictingRecords([]))
                        }
                    }
                    
                    return resolver.reject(error.ckReadable)
                }
                
                resolver.fulfill(.success)
            }
            
            perform(operation)
        }
    }
}

extension CKModification
{
    enum Result
    {
        case success
        case conflictingRecords([CKRecord])
    }
    
    static var maxBatchSize: Int { return 400 }
}

typealias CKModification = CKModifyRecordsOperation

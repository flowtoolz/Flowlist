import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    
    
    func fetchUserCKRecord() -> Promise<CKRecord>
    {
        return firstly
        {
            CKContainer.default().fetchUserCKRecordID()
        }
        .then(on: queue)
        {
            self.fetchCKRecords(withIDs: [$0])
        }
        .map(on: queue)
        {
            guard let record = $0.first else
            {
                let errorMessage = "No user record found"
                log(error: errorMessage)
                throw ReadableError.message(errorMessage)
            }
            
            return record
        }
    }
    
    func fetchCKRecords(withIDs ids: [CKRecord.ID]) -> Promise<[CKRecord]>
    {
        let operation = CKFetchRecordsOperation(recordIDs: ids)
        
        return Promise
        {
            resolver in
            
            setTimeout(on: operation, or: resolver)

            operation.perRecordCompletionBlock =
            {
                record, id, error in
                
                // for overall progress updates
            }
            
            operation.fetchRecordsCompletionBlock =
            {
                recordsByID, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                }
                
                guard let recordsByID = recordsByID else
                {
                    resolver.resolve([], error?.ckReadable)
                    return
                }
        
                resolver.resolve(Array(recordsByID.values), error?.ckReadable)
            }
            
            perform(operation)
        }
    }
}

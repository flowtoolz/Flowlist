import CloudKit
import PromiseKit
import SwiftyToolz

// TODO: note about syncing deletions: deletions cannot cause CloudKit conflicts! when server or client has deleted a record while the other side has modified it, the client would probably win when applying his change or deletion to the server. however if in the case of deletion vs. modification the modification should always win, then do this on resync: first save modified records to server and resolve conflicts reported by CloudKit, then fetch changes from server and apply them locally, then check the client's own deletions and only apply those that do not correspond to fetched record changes...

extension CKDatabase
{
    func deleteCKRecords(ofType type: String,
                         inZone zoneID: CKRecordZone.ID) -> Promise<DeletionResult>
    {
        return firstly
        {
            queryCKRecords(ofType: type, inZone: zoneID)
        }
        .map(on: iCloudQueue)
        {
            $0.map { $0.recordID }
        }
        .then(on: iCloudQueue)
        {
            self.deleteCKRecords(with: $0)
        }
    }
    
    func deleteCKRecords(with ids: [CKRecord.ID]) -> Promise<DeletionResult>
    {
        return ids.count > maxDeletionBatchSize
            ? deleteCKRecordsInBatches(with: ids)
            : deleteCKRecordsInOneBatch(with: ids)
    }
    
    private func deleteCKRecordsInBatches(with ids: [CKRecord.ID]) -> Promise<DeletionResult>
    {
        let batches = ids.splitIntoSlices(ofSize: maxDeletionBatchSize).map(Array.init)
        
        return firstly
        {
            when(resolved: batches.map(deleteCKRecordsInOneBatch))
        }
        .map(on: iCloudQueue)
        {
            (promiseResults: [Result<DeletionResult>]) -> DeletionResult in
            
            return try self.deletionResult(from: promiseResults)
        }
    }
    
    private func deletionResult(from promiseResults: [Result<DeletionResult>]) throws -> DeletionResult
    {
        // TODO: throw error only if ALL batches failed. if at least one batch succeeded, create an integrated modification result that expresses everything that failed and everything that succeeded, merging the returned modification results into one
        
        return .ok
    }

    private func deleteCKRecordsInOneBatch(with ids: [CKRecord.ID]) -> Promise<DeletionResult>
    {
        let operation = CKModifyRecordsOperation(recordsToSave: nil,
                                                 recordIDsToDelete: ids)
    
        var result = DeletionResult()
        
        return Promise
        {
            resolver in
            
            setTimeout(on: operation, or: resolver)
            
            operation.modifyRecordsCompletionBlock =
            {
                _, idsOfDeletedRecords, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                    
                    guard let ckError = error.ckError,
                        ckError.code == .partialFailure,
                        let errorsByID = ckError.partialErrorsByItemID as? [CKRecord.ID : Error]
                    else
                    {
                        return resolver.reject(error.ckReadable)
                    }
                    
                    result.failedDeletions = Array(errorsByID.keys)
                }

                result.idsOfDeletedRecords = idsOfDeletedRecords ?? []
                resolver.fulfill(result)
            }
            
            perform(operation)
        }
    }
}

struct DeletionResult
{
    static var ok: DeletionResult { return DeletionResult() }
    
    var idsOfDeletedRecords = [CKRecord.ID]()
    var failedDeletions = [CKRecord.ID]()
}

private let maxDeletionBatchSize = 400

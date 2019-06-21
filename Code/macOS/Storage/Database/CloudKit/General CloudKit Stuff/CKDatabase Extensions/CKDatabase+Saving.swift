import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    func save(_ ckRecords: [CKRecord]) -> Promise<SaveResult>
    {
        guard !ckRecords.isEmpty else
        {
            log(warning: "Tried to save empty array of CKRecords to iCloud.")
            return .value(.ok)
        }
        
        return ckRecords.count > maxSaveBatchSize
            ? saveInBatches(ckRecords)
            : saveInOneBatch(ckRecords)
    }
    
    private func saveInBatches(_ ckRecords: [CKRecord]) -> Promise<SaveResult>
    {
        let batches = ckRecords.splitIntoSlices(ofSize: maxSaveBatchSize).map(Array.init)
        
        return when(resolved: batches.map(saveInOneBatch)).map
        {
            (promiseResults: [Result<SaveResult>]) -> SaveResult in
            
            // TODO: map properly. throw error only if ALL batches failed. if at least one batch succeeded, create an integrated modification result that expresses everything that failed and everything that succeeded, merging the returned modification results into one
            // from PromiseKit docs: "The array is ordered the same as the input, ie. the result order is *not* resolution order."
            // ... so we can identify batches by index in order to merge results
            return .ok
        }
    }

    private func saveInOneBatch(_ ckRecords: [CKRecord]) -> Promise<SaveResult>
    {
        let operation = CKModifyRecordsOperation(recordsToSave: ckRecords,
                                                 recordIDsToDelete: nil)

        var result = SaveResult()
        
        operation.perRecordCompletionBlock =
        {
            guard let error = $1 else { return }
            
            if let conflict = SaveConflict(from: error)
            {
                result.conflicts.append(conflict)
            }
            else
            {
                result.failedUpdates.append($0)
            }
        }
        
        return Promise
        {
            resolver in
            
            setTimeout(on: operation, or: resolver)
            
            operation.modifyRecordsCompletionBlock =
            {
                updatedRecords, _, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                    
                    guard let ckError = error.ckError, ckError.code == .partialFailure else
                    {
                        return resolver.reject(error.ckReadable)
                    }
                }

                result.updatedRecords = updatedRecords ?? []
                resolver.fulfill(result)
            }
            
            perform(operation)
        }
    }
}

struct SaveResult
{
    static var ok: SaveResult { return SaveResult() }
    
    var updatedRecords = [CKRecord]()
    var conflicts = [SaveConflict]()
    var failedUpdates = [CKRecord]()
}

// TODO: when the conflict is being resolved, the resolved version should be written to the server record and that record should be written back to the server

struct SaveConflict
{
    init?(from error: Error?)
    {
        guard let ckError = error?.ckError,
            case .serverRecordChanged = ckError.code,
            let clientRecord = ckError.clientRecord,
            let serverRecord = ckError.serverRecord else { return nil }
        
        self.clientRecord = clientRecord
        self.serverRecord = serverRecord
        self.ancestorRecord = ckError.ancestorRecord
    }
    
    let clientRecord: CKRecord
    let serverRecord: CKRecord
    let ancestorRecord: CKRecord? // can't be provided if the client didn't fetch the record from the db but re-created it, in which case the client record's change tag doesn't match any previous change tag of that record on the server
}

private let maxSaveBatchSize = 400

import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    func deleteCKRecords(ofType type: String,
                         inZone zoneID: CKRecordZone.ID) -> Promise<CKModification.Result>
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
    
    func deleteCKRecords(with ids: [CKRecord.ID]) -> Promise<CKModification.Result>
    {
        return ids.count > CKModification.maxBatchSize
            ? deleteCKRecordsInBatches(with: ids)
            : deleteCKRecordsInOneBatch(with: ids)
    }
    
    private func deleteCKRecordsInBatches(with ids: [CKRecord.ID]) -> Promise<CKModification.Result>
    {
        let batches = ids.splitIntoSlices(ofSize: CKModification.maxBatchSize).map(Array.init)
        
        return firstly
        {
            when(resolved: batches.map(deleteCKRecordsInOneBatch))
        }
        .map(on: iCloudQueue)
        {
            (promiseResults: [Result<CKModification.Result>]) -> CKModification.Result in
            
            var conflictingRecords = [CKRecord]()
            var errors = [Error]()
            
            for promiseResult in promiseResults
            {
                switch promiseResult
                {
                case .fulfilled(let modificationResult):
                    switch modificationResult
                    {
                    case .success: break
                    case .conflictingRecords(let records): conflictingRecords += records
                    }
                case .rejected(let error):
                    errors.append(error)
                }
            }
            
            if let error = errors.first
            {
                throw error
            }
            else if !conflictingRecords.isEmpty
            {
                return .conflictingRecords(conflictingRecords)
            }
            else
            {
                return .success
            }
        }
    }
    
    private func deleteCKRecordsInOneBatch(with ids: [CKRecord.ID]) -> Promise<CKModification.Result>
    {
        let operation = CKModification(recordsToSave: nil,
                                       recordIDsToDelete: ids)
        
        return modify(with: operation)
    }
}

import CloudKit
import SwiftyToolz
import PromiseKit

extension CKDatabase
{
    func queryCKRecords(ofType type: CKRecord.RecordType,
                        inZone zoneID: CKRecordZone.ID) -> Promise<[CKRecord]>
    {
        let query = CKQuery(recordType: type, predicate: .all)
        return perform(query, inZone: zoneID)
    }
    
    func perform(_ query: CKQuery, inZone zoneID: CKRecordZone.ID) -> Promise<[CKRecord]>
    {
        return perform(query, inZone: zoneID, cursor: nil)
    }
    
    private func perform(_ query: CKQuery,
                         inZone zoneID: CKRecordZone.ID,
                         cursor: CKQueryOperation.Cursor?) -> Promise<[CKRecord]>
    {
        return firstly
        {
            performAndReturnCursor(query, inZone: zoneID, cursor: cursor)
        }
        .then(on: queue)
        {
            (records, newCursor) -> Promise<[CKRecord]> in
            
            guard let newCursor = newCursor else
            {
                return .value(records)
            }
            
            return firstly
            {
                self.perform(query, inZone: zoneID, cursor: newCursor)
            }
            .map(on: self.queue)
            {
                records + $0
            }
        }
    }
    
    private func performAndReturnCursor(_ query: CKQuery,
                                        inZone zoneID: CKRecordZone.ID,
                                        cursor: CKQueryOperation.Cursor?) -> Promise<([CKRecord], CKQueryOperation.Cursor?)>
    {
        return Promise
        {
            resolver in
        
            let queryOperation = CKQueryOperation(query: query)
            queryOperation.zoneID = zoneID
            
            setTimeout(on: queryOperation, or: resolver)
            
            var records = [CKRecord]()
            
            queryOperation.recordFetchedBlock =
            {
                records.append($0)
            }
            
            queryOperation.queryCompletionBlock =
            {
                cursor, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                    log("Fetched \(records.count) records before the error occured.")
                }
                
                resolver.resolve((records, cursor), error?.ckReadable)
            }
            
            self.perform(queryOperation)
        }
    }
}

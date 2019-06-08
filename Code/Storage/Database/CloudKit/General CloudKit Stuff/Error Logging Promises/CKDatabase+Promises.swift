import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    public func perform(_ query: CKQuery,
                        inZone zoneID: CKRecordZone.ID,
                        cursor: CKQueryOperation.Cursor? = nil) -> Promise<[CKRecord]>
    {
        return firstly
        {
            performAndReturnCursor(query, inZone: zoneID, cursor: cursor)
        }
        .then
        {
            (records, newCursor) -> Promise<[CKRecord]> in
            
            if let newCursor = newCursor
            {
                return firstly
                {
                    self.perform(query, inZone: zoneID, cursor: newCursor)
                }
                .map
                {
                    $0 + records
                }
            }
            else
            {
                return .value(records)
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
            queryOperation.queuePriority = .high
            queryOperation.database = self
            
            if #available(OSX 10.13, *)
            {
                queryOperation.configuration.timeoutIntervalForRequest = 1.0
                queryOperation.configuration.timeoutIntervalForResource = 1.0
            }
            
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
                }
                
                resolver.resolve((records, cursor), error?.ckReadable)
            }
            
            self.add(queryOperation)
        }
    }
    
    public func fetchUserCKRecord() -> Promise<CKRecord>
    {
        return firstly
        {
            CKContainer.default().fetchUserCKRecordID()
        }
        .then(on: DispatchQueue.global(qos: .userInitiated))
        {
            self.fetchCKRecord(withID: $0)
        }
    }
    
    private func fetchCKRecord(withID recordID: CKRecord.ID) -> Promise<CKRecord>
    {
        return Promise
        {
            resolver in
            
            fetch(withRecordID: recordID)
            {
                record, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                }
                
                resolver.resolve(record, error?.ckReadable)
            }
        }
    }
}

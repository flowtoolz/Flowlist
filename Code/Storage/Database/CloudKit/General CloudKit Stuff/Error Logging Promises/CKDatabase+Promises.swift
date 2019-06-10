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
                resolver.reject(ReadableError.message("iCloud query operation didn't respond and was cancelled after \(seconds) seconds."))
            }
        }
    }
    
    #if DEBUG
    static let timeoutAfterSeconds: Double = 5
    #else
    static let timeoutAfterSeconds: Double = 20
    #endif
}

import CloudKit
import PromiseKit
import SwiftyToolz

extension CKDatabase
{
    func perform(_ query: CKQuery,
                 inZone zoneID: CKRecordZone.ID,
                 cursor: CKQueryOperation.Cursor? = nil) -> Promise<[CKRecord]>
    {
        return firstly
        {
            performAndReturnCursor(query, inZone: zoneID, cursor: cursor)
        }
        .then(on: globalQ)
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
            .map(on: self.globalQ)
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
    
    func fetchUserCKRecord() -> Promise<CKRecord>
    {
        return firstly
        {
            CKContainer.default().fetchUserCKRecordID()
        }
        .then(on: globalQ)
        {
            self.fetchCKRecords(withIDs: [$0])
        }
        .map(on: globalQ)
        {
            guard let record = $0.first else
            {
                throw ReadableError.message("No user record found")
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
    
    var globalQ: DispatchQueue { return referenceToGlobalQueue }
}

private let referenceToGlobalQueue = DispatchQueue.global(qos: .userInitiated)

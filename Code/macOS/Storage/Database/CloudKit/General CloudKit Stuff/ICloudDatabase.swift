import CloudKit
import FoundationToolz
import SwiftObserver
import SwiftyToolz
import PromiseKit

class ICloudDatabase: CustomObservable
{
    // MARK: - Save
    
    func save(_ ckRecords: [CKRecord]) -> Promise<ModificationResult>
    {
        guard !ckRecords.isEmpty else
        {
            log(warning: "Tried to save empty array of CKRecords to iCloud.")
            return .value(.success)
        }
        
        return ckRecords.count > maxBatchSize
            ? saveInBatches(ckRecords)
            : saveInOneBatch(ckRecords)
    }
    
    private func saveInBatches(_ ckRecords: [CKRecord]) -> Promise<ModificationResult>
    {
        let batches = ckRecords.splitIntoSlices(ofSize: maxBatchSize).map(Array.init)

        return when(resolved: batches.map(saveInOneBatch)).map
        {
            (promiseResults: [Result<ModificationResult>]) -> ModificationResult in
            
            // TODO: map properly
            
            return .success
        }
    }
    
    private func saveInOneBatch(_ ckRecords: [CKRecord]) -> Promise<ModificationResult>
    {
        let operation = ModifyOperation(recordsToSave: ckRecords,
                                        recordIDsToDelete: nil)
        
        return perform(modifyOperation: operation)
    }
    
    // MARK: - Delete
    
    func deleteCKRecords(ofType type: String,
                         inZone zoneID: CKRecordZone.ID) -> Promise<ModificationResult>
    {
        return firstly
        {
            fetchCKRecords(ofType: type, inZone: zoneID)
        }
        .map(on: queue)
        {
            $0.map { $0.recordID }
        }
        .then(on: queue)
        {
            self.deleteCKRecords(withIDs: $0)
        }
    }
    
    func deleteCKRecords(withIDs ids: [CKRecord.ID]) -> Promise<ModificationResult>
    {
        return ids.count > maxBatchSize
            ? deleteInBatches(ids)
            : deleteInOneBatch(ids)
    }
    
    private func deleteInBatches(_ ckRecordIDs: [CKRecord.ID]) -> Promise<ModificationResult>
    {
        let batches = ckRecordIDs.splitIntoSlices(ofSize: maxBatchSize).map(Array.init)
        
        return when(resolved: batches.map(deleteInOneBatch)).map
        {
            (promiseResults: [Result<ModificationResult>]) -> ModificationResult in
            
            // TODO: properly map
            
            return .success
        }
    }
    
    private func deleteInOneBatch(_ ckRecordIDs: [CKRecord.ID]) -> Promise<ModificationResult>
    {
        let operation = ModifyOperation(recordsToSave: nil,
                                        recordIDsToDelete: ckRecordIDs)
        
        return perform(modifyOperation: operation)
    }
    
    // MARK: - Fetch
    
    func fetchCKRecords(ofType type: CKRecord.RecordType,
                        inZone zoneID: CKRecordZone.ID) -> Promise<[CKRecord]>
    {
        let query = CKQuery(recordType: type, predicate: .all)
        return fetchCKRecords(with: query, inZone: zoneID)
    }
    
    func fetchCKRecords(with query: CKQuery,
                        inZone zoneID: CKRecordZone.ID) -> Promise<[CKRecord]>
    {
        return ckDatabase.perform(query, inZone: zoneID)
    }
    
    func fetchChanges(fromZone zoneID: CKRecordZone.ID) -> Promise<CKDatabase.Changes>
    {
        return ckDatabase.fetchChanges(fromZone: zoneID)
    }
    
    var hasChangeToken: Bool { return ckDatabase.hasServerChangeToken }
    
    // MARK: - Respond to Notifications
    
    func handlePushNotification(with userInfo: [String : Any])
    {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else { return }
        
        switch notification.notificationType
        {
        case .query:
            guard let notification = notification as? CKQueryNotification else
            {
                log(error: "Couldn't cast query notification to CKQueryNotification.")
                break
            }
            
            didReceive(queryNotification: notification)
            
        case .recordZone:
            log(error: "Unexpectedly received iCloud record zone notification.")
            
        case .readNotification:
            log(error: "Unexpectedly received iCloud read notification.")
            
        case .database:
            guard let notification = notification as? CKDatabaseNotification else
            {
                log(error: "Couldn't cast database notification to CKDatabaseNotification.")
                break
            }
            
            didReceive(databaseNotification: notification)
        @unknown default:
            log(error: "unhandled case")
            break
        }
    }
    
    private func didReceive(queryNotification notification: CKQueryNotification)
    {
        guard let recordId = notification.recordID else
        {
            log(error: "iCloud query notification carries no record id.")
            return
        }
        
        switch notification.queryNotificationReason
        {
        case .recordCreated:
            didCreateRecord(with: recordId, notification: notification)
        case .recordUpdated:
            didModifyRecord(with: recordId, notification: notification)
        case .recordDeleted:
            didDeleteRecord(with: recordId)
        @unknown default:
            log(error: "Unknown case of CKQueryNotification.Reason")
        }
    }
    
    // MARK: - Send Updates to Observers
    
    private func didCreateRecord(with id: CKRecord.ID,
                                 notification: CKQueryNotification)
    {
        send(.didCreateRecord(id: id, notification: notification))
    }
    
    private func didModifyRecord(with id: CKRecord.ID,
                         notification: CKQueryNotification)
    {
        send(.didModifyRecord(id: id, notification: notification))
    }
    
    private func didDeleteRecord(with id: CKRecord.ID)
    {
        send(.didDeleteRecord(id: id))
    }
    
    private func didReceive(databaseNotification: CKDatabaseNotification)
    {
        send(.didReceiveDatabaseNotification(databaseNotification))
    }
    
    // MARK: - Create Record Zones
    
    func createZone(with id: CKRecordZone.ID) -> Promise<CKRecordZone>
    {
        let zone = CKRecordZone(zoneID: id)
        
        let operation = CKModifyRecordZonesOperation(recordZonesToSave: [zone],
                                                     recordZoneIDsToDelete: nil)
        
        return Promise
        {
            resolver in
            
            operation.modifyRecordZonesCompletionBlock =
            {
                createdZones, _, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                }
                
                resolver.resolve(error?.ckReadable, createdZones?.first)
            }
            
            perform(operation)
        }
    }
    
    // MARK: - Create Subscription
    
    func createQuerySubscription(forRecordType type: String,
                                 desiredKeys: [String]) -> Promise<CKSubscription>
    {
        let options: CKQuerySubscription.Options =
        [
            .firesOnRecordUpdate,
            .firesOnRecordCreation,
            .firesOnRecordDeletion
        ]
        
        let subscription = CKQuerySubscription(recordType: type,
                                               predicate: .all,
                                               options: options)
        
        return save(subscription, desiredKeys: desiredKeys)
    }
    
    func createDatabaseSubscription(withID id: String) -> Promise<CKSubscription>
    {
        let subID = CKSubscription.ID(id)
        let sub = CKDatabaseSubscription(subscriptionID: subID)
        
        return save(sub)
    }
    
    private func save(_ subscription: CKSubscription,
                      desiredKeys: [CKRecord.FieldKey]? = nil) -> Promise<CKSubscription>
    {
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        notificationInfo.desiredKeys = desiredKeys
        
        subscription.notificationInfo = notificationInfo
        
        return Promise
        {
            resolver in

            // TODO: use CKModifySubscriptionsOperation instead
            
            ckDatabase.save(subscription)
            {
                subscription, error in
                
                if let error = error
                {
                    log(error: error.ckReadable.message)
                }
                
                resolver.resolve(subscription, error?.ckReadable)
            }
        }
    }
    
    // MARK: - Database
    
    private func perform(modifyOperation operation: ModifyOperation) -> Promise<ModificationResult>
    {
        if (operation.recordIDsToDelete?.count ?? 0) +
           (operation.recordsToSave?.count ?? 0) > maxBatchSize
        {
            let message = "Too many items in CKModifyRecordsOperation."
            log(error: message)
            return Promise(error: ReadableError.message(message))
        }
        
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
            
            ckDatabase.setTimeout(on: operation, or: resolver)
            
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
                            resolver.fulfill(.conflictingRecords([]))
                            return
                        }
                    }
                    
                    resolver.reject(error.ckReadable)
                    return
                }
                
                resolver.fulfill(.success)
            }
            
            perform(operation)
        }
    }
    
    private let maxBatchSize = 400
    
    func perform(_ operation: CKDatabaseOperation)
    {
        ckDatabase.perform(operation)
    }
    
    private var ckDatabase: CKDatabase
    {
        return container.privateCloudDatabase
    }
    
    // MARK: - Container
    
    func checkAccountAccess() -> Promise<Void>
    {
        return firstly
        {
            self.container.fetchAccountStatus()
        }
        .map(on: queue)
        {
            status -> Void in
            
            let errorMessage: String? =
            {
                switch status
                {
                case .couldNotDetermine: return "Could not determine iCloud account status."
                case .available: return nil
                case .restricted: return "iCloud account is restricted."
                case .noAccount: return "Cannot access the iCloud account."
                @unknown default: return "Unknown account status."
                }
            }()
            
            if let errorMessage = errorMessage
            {
                log(error: errorMessage)
                throw ReadableError.message(errorMessage)
            }
        }
    }
    
    private let container = CKContainer.default()
    
    var queue: DispatchQueue { return ckDatabase.queue }
    
    // MARK: - Observability
    
    typealias Message = Event
    
    let messenger = Messenger(Event.didNothing)
    
    enum Event
    {
        case didNothing
        case didCreateRecord(id: CKRecord.ID, notification: CKQueryNotification)
        case didModifyRecord(id: CKRecord.ID, notification: CKQueryNotification)
        case didDeleteRecord(id: CKRecord.ID)
        case didReceiveDatabaseNotification(CKDatabaseNotification)
    }
}

enum ModificationResult
{
    case success
    case conflictingRecords([CKRecord])
}

private typealias ModifyOperation = CKModifyRecordsOperation

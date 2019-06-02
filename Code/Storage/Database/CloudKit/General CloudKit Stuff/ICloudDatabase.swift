import CloudKit
import FoundationToolz
import SwiftObserver
import SwiftyToolz
import PromiseKit

class ICloudDatabase: CustomObservable
{
    // MARK: - Save
    
    func save(_ ckRecords: [CKRecord]) -> Promise<Void>
    {
        let slices = ckRecords.splitIntoSlices(ofSize: 400)
        
        let promises = slices.map
        {
            (slice: ArraySlice<CKRecord>) -> Promise<Void> in
            
            let operation = ModifyOperation(recordsToSave: Array(slice),
                                            recordIDsToDelete: nil)
            
            return Promise
            {
                perform(modifyOperation: operation,
                        handleCreationSuccess: $0.resolve,
                        handleDeletionSuccess: nil)
            }
        }
        
        return when(fulfilled: promises)
    }
    
    // MARK: - Delete
    
    func deleteCKRecords(ofType type: String,
                         inZone zoneID: CKRecordZone.ID) -> Promise<Void>
    {
        return firstly
        {
            fetchCKRecords(ofType: type, inZone: zoneID)
        }
        .map(on: backgroundQ)
        {
            $0.map { $0.recordID }
        }
        .then(on: backgroundQ)
        {
            self.deleteCKRecords(withIDs: $0)
        }
    }
    
    func deleteCKRecords(withIDs ids: [CKRecord.ID]) -> Promise<Void>
    {
        let slices = ids.splitIntoSlices(ofSize: 400)

        let promises = slices.map
        {
            (slice: ArraySlice<CKRecord.ID>) -> Promise<Void> in
            
            let operation = ModifyOperation(recordsToSave: nil,
                                            recordIDsToDelete: Array(slice))
            
            return Promise
            {
                perform(modifyOperation: operation,
                        handleCreationSuccess: nil,
                        handleDeletionSuccess: $0.resolve)
            }
        }
        
        return when(fulfilled: promises)
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
        return ckDatabase.perform(query, inZoneWith: zoneID)
    }
    
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
            log(error: "unhandled case")
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
        
        operation.qualityOfService = .userInitiated
        
        return Promise
        {
            resolver in
            
            operation.modifyRecordZonesCompletionBlock =
            {
                createdZones, _, error in
                
                if let error = error?.storageError
                {
                    log(error: error.message)
                }
                
                resolver.resolve(error, createdZones?.first)
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

            ckDatabase.save(subscription)
            {
                subscription, error in
                
                if let error = error?.storageError
                {
                    log(error: error.message)
                }
                
                resolver.resolve(subscription, error)
            }
        }
    }
    
    // MARK: - Database
    
    private func perform(modifyOperation operation: ModifyOperation,
                         handleCreationSuccess: ((Error?) -> Void)?,
                         handleDeletionSuccess: ((Error?) -> Void)?)
    {
        if (operation.recordIDsToDelete?.count ?? 0) +
           (operation.recordsToSave?.count ?? 0) > 400
        {
            let message = "Too many items in CKModifyRecordsOperation."
            
            log(error: message)

            let error = StorageError.message(message)
            
            handleCreationSuccess?(error)
            handleDeletionSuccess?(error)
            
            return
        }
        
        operation.savePolicy = .allKeys
        operation.queuePriority = .high
        
        if let token = appInstallationID.data(using: .utf8)
        {
            operation.clientChangeTokenData = token
        }
        
        operation.perRecordCompletionBlock =
        {
            if let error = $1
            {
                log(error: error.localizedDescription)
            }
        }
        
        operation.modifyRecordsCompletionBlock =
        {
            _, _, error in
            
            if let error = error?.storageError
            {
                log(error: error.message)
            }
            
            handleDeletionSuccess?(error)
            handleCreationSuccess?(error)
        }
        
        perform(operation)
    }
    
    func perform(_ operation: CKDatabaseOperation)
    {
        ckDatabase.add(operation)
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
        .then(on: backgroundQ)
        {
            status -> Promise<Void> in
            
            var message = ""
            
            switch status
            {
            case .couldNotDetermine:
                message = "Could not determine iCloud account status."
            case .available:
                return Promise()
            case .restricted:
                message = "iCloud account is restricted."
            case .noAccount:
                message = "Cannot access the iCloud account."
            @unknown default:
                message = "Unknown account status."
            }
            
            log(error: message)
            
            return Promise(error: StorageError.message(message))
        }
    }
    
    private let container = CKContainer.default()
    
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
    
    // MARK: - Background Queue
    
    private var backgroundQ: DispatchQueue
    {
        return DispatchQueue.global(qos: .userInitiated)
    }
}

fileprivate typealias ModifyOperation = CKModifyRecordsOperation

let appInstallationID: String =
{
    let key = "UserDefaultsKeyAppInstallationID"
    if let storedID = Persistent.string[key] { return storedID }
    let id = String.makeUUID()
    Persistent.string[key] = id
    return id
}()
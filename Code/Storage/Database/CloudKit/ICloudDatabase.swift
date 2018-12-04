import CloudKit
import FoundationToolz
import SwiftObserver
import SwiftyToolz
import PromiseKit

class ICloudDatabase: Database, Observable
{
    // MARK: - Life Cycle
    
    init()
    {
        NetworkReachability.shared.notifyOfChanges(self)
        {
            _ in
           
            firstly
            {
                self.database.fetchUserRecord()
            }
            .tap(self.updateReachability).catch { _ in }
        }
    }
    
    deinit
    {
        removeObservers()
        NetworkReachability.shared.stopNotifying(self)
    }
    
    // MARK: - Save
    
    func save(_ records: [CKRecord]) -> Promise<Void>
    {
        let operation = CKModifyRecordsOperation(recordsToSave: records,
                                                 recordIDsToDelete: nil)
        
        return Promise
        {
            perform(modifyOperation: operation,
                    handleCreationSuccess: $0.resolve,
                    handleDeletionSuccess: nil)
        }
        .tap(updateReachability)
    }
    
    // MARK: - Delete
    
    func deleteRecords(ofType type: String,
                       inZone zoneID: CKRecordZone.ID) -> Promise<Void>
    {
        let queryForType = CKQuery(recordType: type, predicate: .all)
        
        return firstly
        {
            fetchRecords(with: queryForType, inZone: zoneID)
        }
        .map
        {
            $0.map { $0.recordID }
        }
        .then
        {
            self.deleteRecords(withIDs: $0)
        }
    }
    
    func deleteRecords(withIDs ids: [CKRecord.ID]) -> Promise<Void>
    {
        let operation = CKModifyRecordsOperation(recordsToSave: nil,
                                                 recordIDsToDelete: ids)
        
        return Promise
        {
            perform(modifyOperation: operation,
                    handleCreationSuccess: nil,
                    handleDeletionSuccess: $0.resolve)
        }
        .tap(updateReachability)
    }
    
    // MARK: - Fetch
    
    func fetchRecord(with id: CKRecord.ID) -> Promise<CKRecord>
    {
        let mainQ = DispatchQueue.main
        
        return database.fetch(withRecordID: id).map(on: mainQ)
        {
            $0
        }
        .tap(updateReachability)
    }
    
    func fetchRecords(with query: CKQuery,
                      inZone zoneID: CKRecordZone.ID) -> Promise<[CKRecord]>
    {
        let mainQ = DispatchQueue.main
        
        return database.perform(query, inZoneWith: zoneID).map(on: mainQ)
        {
            $0
        }
        .tap(updateReachability)
    }
    
    // MARK: - Respond to Notifications
    
    func handlePushNotification(with userInfo: [String : Any])
    {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
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
    
    // MARK: - Create Subscriptions
    
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
    
    func createDatabasSubscription(withID id: String) -> Promise<CKSubscription>
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
        
        return database.save(subscription).tap(updateReachability)
    }
    
    // MARK: - Database
    
    private func perform(modifyOperation operation: CKModifyRecordsOperation,
                         handleCreationSuccess: ((Error?) -> Void)?,
                         handleDeletionSuccess: ((Error?) -> Void)?)
    {
        operation.savePolicy = .changedKeys // TODO: or if server records unchanged? handle "merge conflicts" when multiple devices changed data locally offline...
        
        // TODO: The server may reject large operations. When this occurs, a block reports the CKError.Code.limitExceeded error. Your app should handle this error, and refactor the operation into multiple smaller batches.
        
        operation.clientChangeTokenData = appInstanceToken
        
        operation.perRecordCompletionBlock =
        {
            if let error = $1 { log(error: error.localizedDescription) }
        }
        
        operation.modifyRecordsCompletionBlock =
        {
            records, ids, error in
            
            if let error = error
            {
                handleDeletionSuccess?(error)
                handleCreationSuccess?(error)
                
                return
            }
            
            handleCreationSuccess?(nil)
            handleDeletionSuccess?(nil)
        }
        
        perform(operation)
    }
    
    func perform(_ operation: CKDatabaseOperation)
    {
        database.add(operation)
    }
    
    private var database: CKDatabase
    {
        return container.privateCloudDatabase
    }
    
    // MARK: - Container
    
    func checkAccess() -> Promise<Accessibility>
    {
        return firstly
        {
            container.accountStatus()
        }
        .ensure
        {
            self.isAccessible = false
        }
        .map
        {
            status in
            
            var message = ""
            
            switch status
            {
            case .couldNotDetermine:
                message = "Could not determine iCloud account status."
            case .available:
                self.isAccessible = true
                return Accessibility.accessible
            case .restricted:
                message = "iCloud account is restricted."
            case .noAccount:
                message = "This device is not connected to an iCloud account."
            }
            
            return Accessibility.unaccessible(message)
        }
    }
    
    private(set) var isAccessible: Bool?
    
    private let container = CKContainer.default()
    
    // MARK: - App Installation
    
    private(set) lazy var appInstanceToken: Data? =
    {
        if let id = persister.string(appInstanceIDKey)
        {
            return id.data(using: .utf8)
        }
        
        let newID = String.makeUUID()
        
        persister.set(appInstanceIDKey, newID)
        
        return newID.data(using: .utf8)
    }()
    
    private let appInstanceIDKey = "UserDefaultsKeyAppInstanceID"
    
    // MARK: - Reachability
    
    private func updateReachability<T>(with result: Result<T>)
    {
        if case .rejected(let error) = result
        {
            updateReachability(with: error)
        }
        else
        {
            isReachable <- true
        }
    }
    
    private func updateReachability(with error: Error)
    {
        guard let ckError = error as? CKError else { return }
        
        switch ckError.code
        {
        case .networkUnavailable, .networkFailure:
            isReachable <- false
   
        // unclear where the error originated (local / server)
    case .internalError, .badContainer, .serviceUnavailable, .requestRateLimited, .missingEntitlement, .invalidArguments, .resultsTruncated, .incompatibleVersion, .operationCancelled, .changeTokenExpired, .badDatabase, .quotaExceeded, .managedAccountRestricted:
            break
            
        // errors that suggest the server is reachable
        default: isReachable <- true
        }
    }
    
    let isReachable = Var<Bool>()
    
    // MARK: - Observability
    
    var latestUpdate = Event.didNothing
    
    enum Event
    {
        case didNothing
        case didCreateRecord(id: CKRecord.ID, notification: CKQueryNotification)
        case didModifyRecord(id: CKRecord.ID, notification: CKQueryNotification)
        case didDeleteRecord(id: CKRecord.ID)
        case didReceiveDatabaseNotification(CKDatabaseNotification)
    }
}

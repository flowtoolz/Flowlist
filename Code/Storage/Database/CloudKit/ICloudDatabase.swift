import CloudKit
import FoundationToolz
import SwiftObserver
import SwiftyToolz
import PromiseKit

class ICloudDatabase
{
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
    }
    
    // MARK: - Delete
    
    func deleteRecords(ofType type: String,
                       inZone zoneID: CKRecordZone.ID) -> Promise<Void>
    {
        let queryAll = CKQuery(recordType: type, predicate: .all)
        
        return firstly {
            fetchRecords(with: queryAll, inZone: zoneID)
        }.map {
            $0.map { $0.recordID }
        }.then {
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
    }
    
    // MARK: - Fetch
    
    func fetchRecord(with id: CKRecord.ID) -> Promise<CKRecord>
    {
        let mainQ = DispatchQueue.main
        
        return database.fetch(withRecordID: id).map(on: mainQ) { $0 }
    }
    
    func fetchRecords(with query: CKQuery,
                      inZone zoneID: CKRecordZone.ID) -> Promise<[CKRecord]>
    {
        let mainQ = DispatchQueue.main
        
        return database.perform(query, inZoneWith: zoneID).map(on: mainQ) { $0 }
    }
    
    // MARK: - Respond to Notifications
    
    func handlePushNotification(with userInfo: [String : Any])
    {
        if !Thread.isMainThread
        {
            log(error: "Unexpected: We're on a background thread.")
        }
        
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
            // TODO: could this ever happen? how is it to be handled?? reload all data from icloud??
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
    
    // MARK: - To Overwrite in Subclasses
    
    func didCreateRecord(with id: CKRecord.ID,
                         notification: CKQueryNotification)
    {
        log("Did create record: <\(id.recordName)>")
    }
    
    func didModifyRecord(with id: CKRecord.ID,
                         notification: CKQueryNotification)
    {
        log("Did modify record: <\(id.recordName)>")
    }
    
    func didDeleteRecord(with id: CKRecord.ID)
    {
        log("Did delete record: <\(id.recordName)>")
    }
    
    func didReceive(databaseNotification: CKDatabaseNotification)
    {
        log("Did receive database notification.")
    }
    
    // MARK: - Creating Subscriptions
    
    func createQuerySubscription(forRecordType type: String,
                                 desiredTags: [String]) -> Promise<CKSubscription>
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
        
        return save(subscription)
    }
    
    func createDatabasSubscription(withID id: String) -> Promise<CKSubscription>
    {
        let subID = CKSubscription.ID(id)
        let sub = CKDatabaseSubscription(subscriptionID: subID)
        
        return save(sub)
    }
    
    private func save(_ subscription: CKSubscription,
                      desiredTags: [CKRecord.FieldKey]? = nil) -> Promise<CKSubscription>
    {
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        
        subscription.notificationInfo = notificationInfo
        
        return database.save(subscription)
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
            record, error in
            
            if let error = error
            {
                log(error)
                
                // TODO: remember failed records and handle them / try again later...
            }
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
        
        database.add(operation)
    }
    
    var database: CKDatabase
    {
        return container.privateCloudDatabase
    }
    
    // MARK: - Container
    
    func checkAvailability() -> Promise<Availability>
    {
        return firstly {
            container.accountStatus()
        }.ensure {
            self.isAvailable = false
        }.map { status in
            var message = "Copuld not determine iCloud account status."
            
            switch status
            {
            case .couldNotDetermine:
                message = "Could not determine iCloud account status."
            case .available:
                self.isAvailable = true
                return Availability.available
            case .restricted:
                message = "iCloud account is restricted."
            case .noAccount:
                message = "This device is not connected to an iCloud account."
            }
            
            return Availability.unavailable(message)
        }
    }
    
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
    
    private(set) var isAvailable: Bool?
    
    let container = CKContainer.default()
}

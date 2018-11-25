import CloudKit
import FoundationToolz
import SwiftObserver
import SwiftyToolz

class ICloudDatabase
{
    // MARK: - Save
    
    func save(_ records: [CKRecord],
              handleSuccess: @escaping (Bool) -> Void)
    {
        let operation = CKModifyRecordsOperation(recordsToSave: records,
                                                 recordIDsToDelete: nil)
        
        perform(operation: operation,
                handleCreationSuccess: handleSuccess,
                handleDeletionSuccess: nil)
    }
    
    // MARK: - Delete
    
    func deleteRecords(ofType type: String,
                       handleSuccess: @escaping (Bool) -> Void)
    {
        let queryAll = CKQuery(recordType: type, predicate: .all)
        
        fetchRecords(with: queryAll)
        {
            guard let records = $0 else
            {
                handleSuccess(false)
                return
            }
            
            let ids = records.map { $0.recordID }
            
            self.deleteRecords(withIDs: ids, handleSuccess: handleSuccess)
        }
    }
    
    func deleteRecords(withIDs ids: [CKRecord.ID],
                       handleSuccess: @escaping (Bool) -> Void)
    {
        let operation = CKModifyRecordsOperation(recordsToSave: nil,
                                                 recordIDsToDelete: ids)
        
        perform(operation: operation,
                handleCreationSuccess: nil,
                handleDeletionSuccess: handleSuccess)
    }
    
    // MARK: - Fetch
    
    func fetchRecord(with id: CKRecord.ID,
                     handleResult: @escaping (CKRecord?) -> Void)
    {
        database.fetch(withRecordID: id)
        {
            record, error in
            
            DispatchQueue.main.async
            {
                if let error = error
                {
                    log(error: error.localizedDescription)
                    handleResult(nil)
                    return
                }
                
                if record == nil
                {
                    log(error: "The fetched record is nil.")
                }
                
                handleResult(record)
            }
        }
    }
    
    func fetchRecords(with query: CKQuery,
                      handleResult: @escaping ([CKRecord]?) -> Void)
    {
        database.perform(query, inZoneWith: .default)
        {
            records, error in
            
            DispatchQueue.main.async
            {
                if let error = error
                {
                    log(error: error.localizedDescription)
                    handleResult(nil)
                    return
                }
                
                if records == nil
                {
                    log(error: "The fetched record array is nil.")
                }
                
                handleResult(records)
            }
        }
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
                                 desiredTags: [String])
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
        
        save(subscription)
    }
    
    func createDatabasSubscription()
    {
        let subID = CKSubscription.ID("ItemDataBaseSuscription")
        let sub = CKDatabaseSubscription(subscriptionID: subID)
        
        save(sub)
    }
    
    func save(_ subscription: CKSubscription,
              desiredTags: [CKRecord.FieldKey]? = nil)
    {
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription)
        {
            savedSubscription, error in
            
            if let error = error
            {
                log(error: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Database
    
    private func perform(operation: CKModifyRecordsOperation,
                         handleCreationSuccess: ((Bool) -> Void)?,
                         handleDeletionSuccess: ((Bool) -> Void)?)
    {
        operation.database = database
        operation.savePolicy = .changedKeys // TODO: or if server records unchanged? handle "merge conflicts" when multiple devices changed data locally offline...
        
        // TODO: The server may reject large operations. When this occurs, a block reports the CKError.Code.limitExceeded error. Your app should handle this error, and refactor the operation into multiple smaller batches.
        
        operation.perRecordCompletionBlock =
        {
            record, error in
            
            if let error = error
            {
                log(error: error.localizedDescription)
                
                // TODO: remember failed records and handle them / try again later...
            }
        }
        
        operation.modifyRecordsCompletionBlock =
        {
            records, ids, error in
            
            if let error = error
            {
                log(error: error.localizedDescription)
                handleDeletionSuccess?(false)
                handleCreationSuccess?(false)
                return
            }
            
            handleCreationSuccess?(records != nil)
            handleDeletionSuccess?(ids != nil)
        }
        
        operation.start()
    }
    
    var database: CKDatabase
    {
        return container.privateCloudDatabase
    }
    
    // MARK: - Container
    
    func checkAvailability(handleResult: @escaping (_ available: Bool, _ errorMessage: String?) -> Void)
    {
        container.accountStatus
        {
            status, error in
            
            DispatchQueue.main.async
            {
                if let error = error
                {
                    self.isAvailable = false
                    log(error: error.localizedDescription)
                    handleResult(false, error.localizedDescription)
                    return
                }
                
                var errorMessage: String?
                
                switch status
                {
                case .couldNotDetermine:
                    errorMessage = "Could not determine iCloud account status."
                case .available: break
                case .restricted:
                    errorMessage = "iCloud account is restricted."
                case .noAccount:
                    errorMessage = "This device is not connected to an iCloud account."
                }
                
                if let errorMessage = errorMessage
                {
                    log(error: errorMessage)
                }
                
                let available = errorMessage == nil
                self.isAvailable = available
                handleResult(available, errorMessage)
            }
        }
    }
    
    private(set) var isAvailable: Bool?
    
    let container = CKContainer.default()
}

import CloudKit
import SwiftyToolz

class ICloudDatabase
{
    // MARK: - Fetch
    
    func fetchRecord(with id: CKRecordID,
                     handleResult: @escaping (CKRecord?) -> Void)
    {
        database.fetch(withRecordID: id)
        {
            record, error in
            
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
    
    func fetchRecords(with query: CKQuery,
                      handleResult: @escaping ([CKRecord]?) -> Void)
    {
        database.perform(query, inZoneWith: .default)
        {
            records, error in
            
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
    
    // MARK: - Save
    
    func save(_ record: CKRecord,
              handleResult: @escaping (CKRecord?) -> Void)
    {
        database.save(record)
        {
            savedRecord, error in
            
            if let error = error
            {
                log(error: error.localizedDescription)
                handleResult(nil)
                return
            }
            
            if savedRecord == nil
            {
                log(error: "Result record is nil.")
            }
            
            handleResult(savedRecord)
        }
    }
    
    func save(_ records: [CKRecord])
    {
        let operation = CKModifyRecordsOperation(recordsToSave: records,
                                                 recordIDsToDelete: nil)
        
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
            records, _, error in
            
            if let error = error
            {
                log(error: error.localizedDescription)
            }
            
            // TODO: handle completion
        }
        
        operation.start()
    }
    
    // MARK: - Observing Records
    
    func didReceiveRemoteNotification(with userInfo: [String : Any])
    {
        let notification = CKNotification(fromRemoteNotificationDictionary: userInfo)
        
        guard notification.notificationType == .query,
            let queryNotification = notification as? CKQueryNotification
        else
        {
            return
        }
        
        guard let recordId = queryNotification.recordID else
        {
            log(error: "iCloud query notification carries no record id.")
            // TODO: could this ever happen? how is it to be handled?? reload all data from icloud??
            return
        }
        
        switch queryNotification.queryNotificationReason
        {
        case .recordCreated:
            didCreateRecord(with: recordId, notification: queryNotification)
        case .recordUpdated:
            didModifyRecord(with: recordId, notification: queryNotification)
        case .recordDeleted:
            didDeleteRecord(with: recordId)
        }
    }
    
    func didCreateRecord(with id: CKRecordID,
                         notification: CKQueryNotification)
    {
        log("Did create record: <\(id.recordName)>")
    }
    
    func didModifyRecord(with id: CKRecordID,
                         notification: CKQueryNotification)
    {
        log("Did modify record: <\(id.recordName)>")
    }
    
    func didDeleteRecord(with id: CKRecordID)
    {
        log("Did delete record: <\(id.recordName)>")
    }
    
    func createSubscription(forRecordType type: String,
                            desiredTags: [String],
                            alertLocalizationKey key: String)
    {
        let options: CKSubscriptionOptions =
        [
            .firesOnRecordUpdate,
            .firesOnRecordCreation,
            .firesOnRecordDeletion
        ]
        
        let subscription = CKSubscription(recordType: type,
                                          predicate: NSPredicate(value: true),
                                          options: options)
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.alertLocalizationKey = key
        notificationInfo.desiredKeys = desiredTags
        notificationInfo.shouldBadge = false
        
        subscription.notificationInfo = notificationInfo
        
        database.save(subscription)
        {
            savedSubscription, error in
            
            if let error = error
            {
                log( error: error.localizedDescription)
            }
        }
    }
    
    // MARK: - Basics
    
    var database: CKDatabase
    {
        return container.privateCloudDatabase
    }
    
    func isICloudAvailable(handleResult: @escaping (Bool) -> Void)
    {
        container.accountStatus
        {
            status, error in
            
            if let error = error
            {
                log(error: error.localizedDescription)
                handleResult(false)
                return
            }
            
            switch status
            {
            case .couldNotDetermine:
                log(error: "Could not determine iCloud account status.")
            case .available:
                handleResult(true)
                return
            case .restricted:
                log(error: "iCloud account is restricted.")
            case .noAccount:
                log(error: "This device is not connected to an iCloud account.")
            }
            
            handleResult(false)
        }
    }
    
    let container = CKContainer.default()
}

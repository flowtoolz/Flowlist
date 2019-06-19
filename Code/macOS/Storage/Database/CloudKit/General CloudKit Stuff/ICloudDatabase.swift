import CloudKit
import FoundationToolz
import SwiftObserver
import SwiftyToolz
import PromiseKit

// TODO: move all the saving, fetching, deleting to CKDatabase extensions. and possibly even the setup stuff. move account status check to CKContainer extension.

/**
 A wrapper around CKDatabase **and** CKContainer. It provides observability, setup and availability ckecking.
 */
class ICloudDatabase: CustomObservable
{
    // MARK: - Save
    
    func save(_ ckRecords: [CKRecord]) -> Promise<CKModification.Result>
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
    
    private func saveInBatches(_ ckRecords: [CKRecord]) -> Promise<CKModification.Result>
    {
        let batches = ckRecords.splitIntoSlices(ofSize: maxBatchSize).map(Array.init)

        return when(resolved: batches.map(saveInOneBatch)).map
        {
            (promiseResults: [Result<CKModification.Result>]) -> CKModification.Result in
            
            // TODO: map properly
            
            return .success
        }
    }
    
    private func saveInOneBatch(_ ckRecords: [CKRecord]) -> Promise<CKModification.Result>
    {
        let operation = CKModification(recordsToSave: ckRecords,
                                        recordIDsToDelete: nil)
        
        return ckDatabase.modify(with: operation)
    }
    
    // MARK: - Delete
    
    func deleteCKRecords(ofType type: String,
                         inZone zoneID: CKRecordZone.ID) -> Promise<CKModification.Result>
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
    
    func deleteCKRecords(withIDs ids: [CKRecord.ID]) -> Promise<CKModification.Result>
    {
        return ids.count > maxBatchSize
            ? deleteInBatches(ids)
            : deleteInOneBatch(ids)
    }
    
    private func deleteInBatches(_ ckRecordIDs: [CKRecord.ID]) -> Promise<CKModification.Result>
    {
        let batches = ckRecordIDs.splitIntoSlices(ofSize: maxBatchSize).map(Array.init)
        
        return when(resolved: batches.map(deleteInOneBatch)).map
        {
            (promiseResults: [Result<CKModification.Result>]) -> CKModification.Result in
            
            // TODO: properly map
            
            return .success
        }
    }
    
    private func deleteInOneBatch(_ ckRecordIDs: [CKRecord.ID]) -> Promise<CKModification.Result>
    {
        let operation = CKModification(recordsToSave: nil,
                                        recordIDsToDelete: ckRecordIDs)
        
        return ckDatabase.modify(with: operation)
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
    
    func createDatabaseSubscription(withID id: String) -> Promise<CKSubscription>
    {
        return ckDatabase.createSubscription(withID: id)
    }

    // MARK: - Database + Performing Operations
    
    func perform(_ operation: CKDatabaseOperation)
    {
        ckDatabase.perform(operation)
    }
    
    var queue: DispatchQueue { return iCloudQueue }
    
    private var maxBatchSize: Int { return CKModification.maxBatchSize }
    
    private var ckDatabase: CKDatabase
    {
        return container.privateCloudDatabase
    }
    
    // MARK: - Container + Account Status
    
    func ensureAccountAccess() -> Promise<Void>
    {
        return container.ensureAccountAccess()
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
}

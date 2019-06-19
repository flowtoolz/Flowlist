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
            queryCKRecords(ofType: type, inZone: zoneID)
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
    
    func queryCKRecords(ofType type: CKRecord.RecordType,
                        inZone zoneID: CKRecordZone.ID) -> Promise<[CKRecord]>
    {
        return ckDatabase.queryCKRecords(ofType: type, inZone: zoneID)
    }
    
    func perform(_ query: CKQuery, inZone zoneID: CKRecordZone.ID) -> Promise<[CKRecord]>
    {
        return ckDatabase.perform(query, inZone: zoneID)
    }
    
    func fetchChanges(fromZone zoneID: CKRecordZone.ID) -> Promise<CKDatabase.Changes>
    {
        return ckDatabase.fetchChanges(fromZone: zoneID)
    }
    
    var hasChangeToken: Bool { return ckDatabase.hasServerChangeToken }
    
    // MARK: - Setup
    
    func createZone(with id: CKRecordZone.ID) -> Promise<CKRecordZone>
    {
        return ckDatabase.createZone(with: id)
    }
    
    func createDatabaseSubscription(withID id: String) -> Promise<CKSubscription>
    {
        return ckDatabase.createSubscription(withID: id)
    }
    
    func ensureAccountAccess() -> Promise<Void>
    {
        return ckContainer.ensureAccountAccess()
    }

    // MARK: - Basics: Container and Database
    
    func perform(_ operation: CKDatabaseOperation)
    {
        ckDatabase.perform(operation)
    }
    
    var queue: DispatchQueue { return iCloudQueue }
    
    private var maxBatchSize: Int { return CKModification.maxBatchSize }
    
    private var ckDatabase: CKDatabase
    {
        return ckContainer.privateCloudDatabase
    }
    
    private let ckContainer = CKContainer.default()
    
    // MARK: - Observability of Notifications
    
    func handlePushNotification(with userInfo: [String : Any])
    {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo) else
        {
            return
        }
        
        switch notification.notificationType
        {
        case .query:
            log(error: "Unexpectedly received iCloud query notification.")
            
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
            send(notification)
            
        @unknown default:
            log(error: "Unknown CloudKit notification type")
        }
    }
    
    typealias Message = CKDatabaseNotification?
    
    let messenger = Messenger<CKDatabaseNotification?>()
}

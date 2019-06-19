import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

/**
 A wrapper around CKDatabase **and** CKContainer. It provides observability, setup and availability ckecking.
 */
class ICloudDatabase: CustomObservable
{
    // MARK: - Save
    
    func save(_ ckRecords: [CKRecord]) -> Promise<CKModification.Result>
    {
        return ckDatabase.save(ckRecords)
    }
    
    // MARK: - Delete
    
    func deleteCKRecords(ofType type: String,
                         inZone zoneID: CKRecordZone.ID) -> Promise<CKModification.Result>
    {
        return ckDatabase.deleteCKRecords(ofType: type, inZone: zoneID)
    }
    
    func deleteCKRecords(withIDs ids: [CKRecord.ID]) -> Promise<CKModification.Result>
    {
        return ckDatabase.deleteCKRecords(with: ids)
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
        
        guard case .database = notification.notificationType,
            let dbNotification = notification as? CKDatabaseNotification
        else
        {
            return log(error: "Received unexpected iCloud notification: \(notification.debugDescription).")
        }
        
        send(dbNotification)
    }
    
    typealias Message = CKDatabaseNotification?
    let messenger = Messenger<CKDatabaseNotification?>()
}

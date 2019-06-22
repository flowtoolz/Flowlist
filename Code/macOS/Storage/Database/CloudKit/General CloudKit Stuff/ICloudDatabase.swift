import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

/**
 A wrapper around CKDatabase **and** CKContainer. It provides observability, setup, availability ckecking and cashing of CKRecord system fields
 */
class ICloudDatabase: CustomObservable
{
    // MARK: - Save and Delete
    
    func save(_ ckRecords: [CKRecord]) -> Promise<SaveResult>
    {
        return ckDatabase.save(ckRecords)
    }
    
    func deleteCKRecords(ofType type: String,
                         inZone zoneID: CKRecordZone.ID) -> Promise<DeletionResult>
    {
        return ckDatabase.deleteCKRecords(ofType: type, inZone: zoneID)
    }
    
    func deleteCKRecords(withIDs ids: [CKRecord.ID]) -> Promise<DeletionResult>
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
    
    init(scope: CKDatabase.Scope)
    {
        switch scope
        {
        case .public:
            ckDatabase = ckContainer.publicCloudDatabase
        case .private:
            ckDatabase = ckContainer.privateCloudDatabase
        case .shared:
            ckDatabase = ckContainer.sharedCloudDatabase
        @unknown default:
            log(error: "Unknown CKDatabase.Scope: \(scope)")
            ckDatabase = ckContainer.privateCloudDatabase
        }
    }
    
    func perform(_ operation: CKDatabaseOperation)
    {
        ckDatabase.perform(operation)
    }
    
    var queue: DispatchQueue { return ckDatabase.queue }
    
    private let ckDatabase: CKDatabase
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

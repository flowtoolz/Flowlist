import CloudKit
import CloudKid
import PromiseKit
import SwiftObserver
import SwiftyToolz

class CloudKitDatabase: CloudDatabase, Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    init() { observeCKDatabaseController() }
    
    deinit { stopObserving() }
    
    // MARK: - Reset All Records
    
    func reset(with records: [Record]) -> Promise<CloudDatabaseSaveResult>
    {
        return Promise<CloudDatabaseSaveResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.deleteCKRecords(ofType: .item,
                                                          inZone: .item).map { _ in }
            }
            .then(on: queue)
            {
                // TODO: conflicts should not occur after deleting all records, so throw/log an error in that case
                self.save(records)
            }
            .done(on: queue)
            {
                resolver.fulfill($0)
            }
            .catch
            {
                self.didEnsureAccess = false
                resolver.reject($0)
            }
        }
    }
    
    // MARK: - Save Records
    
    func save(_ records: [Record]) -> Promise<CloudDatabaseSaveResult>
    {
        return Promise<CloudDatabaseSaveResult>
        {
            resolver in
            
            return firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.save(records.map(self.makeCKRecord))
            }
            .map(on: queue)
            {
                $0.makeCloudDatabaseSaveResult()
            }
            .done(on: queue)
            {
                resolver.fulfill($0)
            }
            .catch
            {
                self.didEnsureAccess = false
                resolver.reject($0)
            }
        }
    }
    
    private func makeCKRecord(for record: Record) -> CKRecord
    {
        let ckRecord = ckDatabaseController.getCKRecordWithCachedSystemFields(id: record.id,
                                                                              type: .item,
                                                                              zoneID: .item)
        
        ckRecord.text = record.text
        ckRecord.state = record.state
        ckRecord.tag = record.tag
        
        ckRecord.superItem = record.rootID
        ckRecord.position = record.position
        
        return ckRecord
    }
    
    // MARK: - Delete Records
    
    func deleteRecords(withIDs ids: [String]) -> Promise<CloudDatabaseDeletionResult>
    {
        return Promise<CloudDatabaseDeletionResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.deleteCKRecords(withIDs: ids.itemCKRecordIDs)
            }
            .map(on: queue)
            {
                $0.makeCloudDatabaseDeletionResult()
            }
            .done(on: queue)
            {
                resolver.fulfill($0)
            }
            .catch
            {
                self.didEnsureAccess = false
                resolver.reject($0)
            }
        }
    }
    
    // MARK: - Fetch Stuff
    
    func fetchRecords() -> Promise<[Record]>
    {
        return Promise<[Record]>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.queryCKRecords(ofType: .item, inZone: .item)
            }
            .map(on: queue)
            {
                $0.map { $0.makeRecord() }
            }
            .done(on: queue)
            {
                resolver.fulfill($0)
            }
            .catch
            {
                self.didEnsureAccess = false
                resolver.reject($0)
            }
        }
    }
    
    func fetchChanges() -> Promise<CloudDatabaseChanges>
    {
        return Promise<CloudDatabaseChanges>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.fetchChanges(fromZone: .item)
            }
            .map(on: queue)
            {
                $0.makeCloudDatabaseChanges()
            }
            .done(on: queue)
            {
                resolver.fulfill($0)
            }
            .catch
            {
                self.didEnsureAccess = false
                resolver.reject($0)
            }
        }
    }
    
    var hasChangeToken: Bool
    {
        return ckDatabaseController.hasChangeToken(forZone: .item)
    }
    
    // MARK: - Ensure Access
    
    private func ensureAccess() -> Promise<Void>
    {
        if didEnsureAccess { return Promise() }
        
        if let currentlyRunningPromise = ensuringAccessPromise
        {
            log(warning: "Called \(#function) more than once in parallel. Gonna return the active promise.")
            return currentlyRunningPromise
        }
        
        let newPromise: Promise<Void> = Promise
        {
            resolver in
            
            firstly
            {
                self.ckDatabaseController.ensureAccountAccess()
            }
            .then(on: queue)
            {
                self.ensureItemRecordZoneExists()
            }
            .then(on: queue)
            {
                self.ensureDatabaseSubscriptionExists()
            }
            .done(on: queue)
            {
                self.didEnsureAccess = true
                resolver.fulfill_()
            }
            .ensure(on: queue)
            {
                self.ensuringAccessPromise = nil
            }
            .catch
            {
                self.didEnsureAccess = false
                resolver.reject($0)
            }
        }
        
        ensuringAccessPromise = newPromise.isPending ? newPromise : nil
        
        return newPromise
    }
    
    private var didEnsureAccess = false
    private var ensuringAccessPromise: Promise<Void>?
    
    // MARK: - Observable Database Subscription 
    
    private func ensureDatabaseSubscriptionExists() -> Promise<Void>
    {
        let dbSubID = "ItemDataBaseSubscription"
        
        return ckDatabaseController.createDatabaseSubscription(withID: dbSubID).map { _ in }
    }
    
    func handleDatabaseNotification(with userInfo: [String : Any])
    {
        ckDatabaseController.handleDatabaseNotification(with: userInfo)
    }
    
    private func observeCKDatabaseController()
    {
        observe(ckDatabaseController).select(.didReceiveDatabaseNotification)
        {
            [weak self] in self?.send(.mayHaveChanged)
        }
    }
    
    let messenger = Messenger<CloudDatabaseUpdate?>()
    typealias Message = CloudDatabaseUpdate?
    
    // MARK: - Create Zone
    
    private func ensureItemRecordZoneExists() -> Promise<Void>
    {
        return ckDatabaseController.createZone(with: .item).map { _ in }
    }
    
    // MARK: - CloudKit Database Controller
    
    var queue: DispatchQueue { return ckDatabaseController.queue }
    
    private let ckDatabaseController = CKDatabaseController(databaseScope: .private,
                                                            cacheName: "Flowlist iCloud Cache")
}

private extension Array where Element == String
{
    var itemCKRecordIDs: [CKRecord.ID]
    {
        return map(CKRecord.ID.init(itemID:))
    }
}

import CloudKit
import CloudKid
import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemICloudDatabase: Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    init() { observeCKDatabaseController() }
    
    deinit { stopObserving() }
    
    // MARK: - Edit Items
    
    func save(_ records: [Record]) -> Promise<ItemDatabaseSaveResult>
    {
        return firstly
        {
            save(records.map(makeCKRecord))
        }
        .map
        {
            ckSaveResult -> ItemDatabaseSaveResult in
            
            // TODO: map properly
            
            return .success
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
    
    private func save(_ ckRecords: [CKRecord]) -> Promise<CKSaveResult>
    {
        return Promise<CKSaveResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.save(ckRecords)
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
    
    func deleteRecords(with ids: [String]) -> Promise<ItemDatabaseDeletionResult>
    {
        let ckRecordIDs = ids.map(CKRecord.ID.init(itemID:))
        
        return Promise<ItemDatabaseDeletionResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.deleteCKRecords(withIDs: ckRecordIDs)
            }
            .map
            {
                ckDeletionResult -> ItemDatabaseDeletionResult in
                
                // TODO: map properly
                
                return ItemDatabaseDeletionResult.success
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
    
    func deleteRecords() -> Promise<CKDeletionResult>
    {
        return Promise<CKDeletionResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.deleteCKRecords(ofType: .item, inZone: .item)
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
    
    // MARK: - Fetch Records
    
    func fetchItemCKRecords() -> Promise<[CKRecord]>
    {
        return Promise<[CKRecord]>
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
    
    private func fetchSubitemCKRecords(ofItemWithID id: CKRecord.ID) -> Promise<[CKRecord]>
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        let fetchQuery = CKQuery(recordType: .item, predicate: predicate)
        
        return Promise<[CKRecord]>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.perform(fetchQuery, inZone: .item)
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
    
    // MARK: - Fetch Changes
    
    func fetchChanges() -> Promise<ItemDatabaseChanges>
    {
        return Promise<ItemDatabaseChanges>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.fetchChanges(fromZone: .item).map
                {
                    $0.makeItemDatabaseChanges()
                }
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
    
    let messenger = Messenger<ItemDatabaseUpdate?>()
    typealias Message = ItemDatabaseUpdate?
    
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

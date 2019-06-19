import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemICloudDatabase: Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    init()
    {
        observe(db) { [weak self] in self?.didReceive(databaseEvent: $0) }
    }
    
    deinit { stopObserving() }
    
    // MARK: - Edit Items
    
    func save(_ records: [Record]) -> Promise<ItemDatabaseModificationResult>
    {
        return firstly
        {
            save(records.map(CKRecord.init))
        }
        .map
        {
            ckModificationResult in
            
            // TODO: map properly
            
            return ItemDatabaseModificationResult.success
        }
    }
    
    func save(_ ckRecords: [CKRecord]) -> Promise<ModificationResult>
    {
        return Promise<ModificationResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.db.save(ckRecords)
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
    
    func removeRecords(with ids: [String]) -> Promise<ItemDatabaseModificationResult>
    {
        let ckRecordIDs = ids.map(CKRecord.ID.init(itemID:))
        
        return Promise<ItemDatabaseModificationResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.db.deleteCKRecords(withIDs: ckRecordIDs)
            }
            .map
            {
                ckModificationResult -> ItemDatabaseModificationResult in
                
                // TODO: map properly
                
                return ItemDatabaseModificationResult.success
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
    
    func deleteRecords() -> Promise<ModificationResult>
    {
        return Promise<ModificationResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.db.deleteCKRecords(ofType: CKRecord.itemType, inZone: .item)
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
                self.db.fetchCKRecords(ofType: CKRecord.itemType, inZone: .item)
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
        let query = CKQuery(recordType: CKRecord.itemType, predicate: predicate)
        
        return Promise<[CKRecord]>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.db.fetchCKRecords(with: query, inZone: .item)
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
                self.db.fetchChanges(fromZone: .item).map(ItemDatabaseChanges.init)
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
    
    var hasChangeToken: Bool { return db.hasChangeToken }
    
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
                self.db.checkAccountAccess()
            }
            .then(on: queue)
            {
                self.ensureItemRecordZoneExists()
            }
            .then(on: queue)
            {
                self.ensureSubscriptionExists()
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
    
    // MARK: - Use a Database Subscription
    
    private func ensureSubscriptionExists() -> Promise<Void>
    {
        return db.createDatabaseSubscription(withID: dbSubID).map { _ in }
    }
    
    private let dbSubID = "ItemDataBaseSubscription"
    
    private func didReceive(databaseEvent event: ICloudDatabase.Event)
    {
        switch event
        {
        case .didNothing: break
        
        case .didCreateRecord, .didModifyRecord, .didDeleteRecord:
            // TODO: in case some users still have a query subscription going, delete it!
            log(error: "Did receive a query subscription event but we only created a database subscription.")
        
        case .didReceiveDatabaseNotification(let notification):
            didReceive(databaseNotification: notification)
        }
    }
    
    private func didReceive(databaseNotification: CKDatabaseNotification)
    {
        guard databaseNotification.databaseScope == .private else
        {
            log(error: "Unexpected database scope: \(databaseNotification.databaseScope.rawValue)")
            return
        }

        send(.mayHaveChanged)
    }
    
    // MARK: - Create Zone
    
    private func ensureItemRecordZoneExists() -> Promise<Void>
    {
        return db.createZone(with: .item).map { _ in }
    }
    
    // MARK: - iCloud Database
    
    func handlePushNotification(with userInfo: [String : Any])
    {
        db.handlePushNotification(with: userInfo)
    }
    
    var queue: DispatchQueue { return db.queue }
    
    private let db = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = Messenger(ItemDatabaseUpdate.mayHaveChanged)
    typealias Message = ItemDatabaseUpdate
}

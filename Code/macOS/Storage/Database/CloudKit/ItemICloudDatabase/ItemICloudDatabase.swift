import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemICloudDatabase: Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    init()
    {
        observe(db) { [weak self] in self?.didReceive(notification: $0) }
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
    
    func save(_ ckRecords: [CKRecord]) -> Promise<CKModification.Result>
    {
        return Promise<CKModification.Result>
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
    
    func deleteRecords() -> Promise<CKModification.Result>
    {
        return Promise<CKModification.Result>
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
                self.db.queryCKRecords(ofType: CKRecord.itemType, inZone: .item)
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
        let fetchQuery = CKQuery(recordType: CKRecord.itemType, predicate: predicate)
        
        return Promise<[CKRecord]>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.db.perform(fetchQuery, inZone: .item)
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
                self.db.fetchChanges(fromZone: .item).map { $0.makeItemDatabaseChanges() }
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
                self.db.ensureAccountAccess()
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
        let dbSubID = "ItemDataBaseSubscription"
        
        return db.createDatabaseSubscription(withID: dbSubID).map { _ in }
    }
    
    private func didReceive(notification: CKDatabaseNotification?)
    {
        guard let notification = notification else { return }
        
        guard notification.databaseScope == .private else
        {
            log(error: "Unexpected database scope: \(notification.databaseScope.rawValue)")
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

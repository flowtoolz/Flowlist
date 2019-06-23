import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemICloudDatabase: Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    init()
    {
        observe(ckDatabaseController)
        {
            [weak self] in self?.didReceive(notification: $0)
        }
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
    
    func save(_ ckRecords: [CKRecord]) -> Promise<SaveResult>
    {
        return Promise<SaveResult>
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
                self.ckDatabaseController.deleteCKRecords(withIDs: ckRecordIDs)
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
    
    func deleteRecords() -> Promise<DeletionResult>
    {
        return Promise<DeletionResult>
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
    
    var hasChangeToken: Bool { return ckDatabaseController.hasChangeToken }
    
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
        
        return ckDatabaseController.createDatabaseSubscription(withID: dbSubID).map { _ in }
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
        return ckDatabaseController.createZone(with: .item).map { _ in }
    }
    
    // MARK: - iCloud Database
    
    func handlePushNotification(with userInfo: [String : Any])
    {
        ckDatabaseController.handlePushNotification(with: userInfo)
    }
    
    var queue: DispatchQueue { return ckDatabaseController.queue }
    
    private let ckDatabaseController = CKDatabaseController(databaseScope: .private,
                                                            cacheName: "Flowlist iCloud Cache")
    
    // MARK: - Observability
    
    let messenger = Messenger(ItemDatabaseUpdate.mayHaveChanged)
    typealias Message = ItemDatabaseUpdate
}

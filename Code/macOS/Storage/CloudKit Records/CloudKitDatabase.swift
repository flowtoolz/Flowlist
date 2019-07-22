import CloudKit
import CloudKid
import PromiseKit
import SwiftObserver
import SwiftyToolz

/// Flowlist wrapper around CKDatabaseController. Cares for Flowlist specific setup, access and editing of iCloud Database.

class CloudKitDatabase: Observer, CustomObservable
{
    static let shared = CloudKitDatabase()
    
    // MARK: - Life Cycle
    
    private init() { observeCKDatabaseController() }
    
    deinit { stopObserving() }
    
    // MARK: - Save CKRecords
    
    func save(_ ckRecords: [CKRecord]) -> Promise<CKDatabase.SaveResult>
    {
        return Promise<CKDatabase.SaveResult>
        {
            resolver in
            
            return firstly
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
    
    func getCKRecordWithCachedSystemFields(for id: String) -> CKRecord
    {
        return ckDatabaseController.getCKRecordWithCachedSystemFields(id: id,
                                                                      type: .item,
                                                                      zoneID: .item)
    }
    
    // MARK: - Delete Records
    
    func deleteCKRecords(with ids: [String]) -> Promise<CKDatabase.DeletionResult>
    {
        return Promise<CKDatabase.DeletionResult>
        {
            resolver in
            
            firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.deleteCKRecords(with: ids.ckRecordIDs)
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
    
    func fetchCKRecords() -> Promise<[CKRecord]>
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
    
    func fetchChanges() -> Promise<CKDatabase.Changes>
    {
        return Promise<CKDatabase.Changes>
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
    
    func deleteChangeToken()
    {
        ckDatabaseController.deleteChangeToken(forZone: .item)
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
                self.ensureRecordZoneExists()
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
    
    let messenger = Messenger<Event?>()
    typealias Message = Event?
    enum Event { case mayHaveChanged }
    
    // MARK: - Create Zone
    
    private func ensureRecordZoneExists() -> Promise<Void>
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
    var ckRecordIDs: [CKRecord.ID]
    {
        return map(CKRecord.ID.init(itemID:))
    }
}

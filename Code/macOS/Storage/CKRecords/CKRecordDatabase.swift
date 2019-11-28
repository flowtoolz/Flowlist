import CloudKit
import CloudKid
import PromiseKit
import SwiftObserver
import SwiftyToolz

/// Flowlist wrapper around CKDatabaseController. Cares for Flowlist specific setup, access and editing of iCloud Database.

class CKRecordDatabase: Observer, Observable
{
    // MARK: - Life Cycle
    
    static let shared = CKRecordDatabase()
    private init() { observeCKDatabaseController() }
    deinit { stopObserving() }
    
    // MARK: - Save CKRecords
    
    func save(_ records: [CKRecord]) -> Promise<CKDatabase.SaveResult>
    {
        guard !records.isEmpty else { return .value(.empty) }
        
        return Promise<CKDatabase.SaveResult>
        {
            resolver in
            
            return firstly
            {
                ensureAccess()
            }
            .then(on: queue)
            {
                self.ckDatabaseController.save(records)
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
    
    func getCKRecordWithCachedSystemFields(for id: CKRecord.ID) -> CKRecord
    {
        return ckDatabaseController.getCKRecordWithCachedSystemFields(for: id, of: .itemType)
    }
    
    // MARK: - Delete Records
    
    func deleteCKRecords(with ids: [CKRecord.ID]) -> Promise<CKDatabase.DeletionResult>
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
                self.ckDatabaseController.deleteCKRecords(with: ids)
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
                self.ckDatabaseController.fetchChanges(from: .itemZone)
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
        ckDatabaseController.hasChangeToken(for: .itemZone)
    }
    
    func deleteChangeToken()
    {
        ckDatabaseController.deleteChangeToken(for: .itemZone)
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
        ckDatabaseController.createDatabaseSubscription(with: .itemSub).map { _ in }
    }
    
    func handleDatabaseNotification(with userInfo: JSON)
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
    enum Event { case mayHaveChanged }
    
    // MARK: - Create Zone
    
    private func ensureRecordZoneExists() -> Promise<Void>
    {
        ckDatabaseController.create(.itemZone).map { _ in }
    }
    
    // MARK: - CloudKit Database Controller
    
    var queue: DispatchQueue { ckDatabaseController.queue }
    
    private let ckDatabaseController = CKDatabaseController(scope: .private,
                                                            cacheDirectory: CKRecordDatabase.cacheDirectory)
    
    private static var cacheDirectory: URL
    {
        let dir = URL.flowlistDirectory.appendingPathComponent("iCloud Cache")
        FileManager.default.ensureDirectoryExists(dir)
        return dir
    }
}

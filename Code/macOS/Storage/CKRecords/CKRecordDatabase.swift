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
    
    // MARK: - Save CKRecords
    
    func save(_ records: [CKRecord]) -> PromiseKit.Promise<CKDatabase.SaveResult>
    {
        guard !records.isEmpty else { return .value(.empty) }
        
        return PromiseKit.Promise<CKDatabase.SaveResult>
        {
            resolver in
            
            firstly
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
    
    func clearCachedSystemFields()
    {
        ckDatabaseController.clearCachedSystemFields()
    }
    
    // MARK: - Delete Records
    
    func deleteCKRecords(with ids: [CKRecord.ID]) -> PromiseKit.Promise<CKDatabase.DeletionResult>
    {
        return PromiseKit.Promise<CKDatabase.DeletionResult>
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
    
    func fetchChanges() -> PromiseKit.Promise<CKDatabase.Changes>
    {
        return PromiseKit.Promise<CKDatabase.Changes>
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
    
    private func ensureAccess() -> PromiseKit.Promise<Void>
    {
        if didEnsureAccess { return PromiseKit.Promise() }
        
        if let currentlyRunningPromise = ensuringAccessPromise
        {
            log(warning: "Called \(#function) more than once in parallel. Gonna return the active promise.")
            return currentlyRunningPromise
        }
        
        let newPromise: PromiseKit.Promise<Void> = PromiseKit.Promise
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
    private var ensuringAccessPromise: PromiseKit.Promise<Void>?
    
    // MARK: - Observable Database Subscription 
    
    private func ensureDatabaseSubscriptionExists() -> PromiseKit.Promise<Void>
    {
        ckDatabaseController.createDatabaseSubscription(with: .itemSub).map { _ in }
    }
    
    func handleDatabaseNotification(with userInfo: [String: Any])
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
    
    let messenger = Messenger<Event>()
    enum Event { case mayHaveChanged }
    
    // MARK: - Create Zone
    
    private func ensureRecordZoneExists() -> PromiseKit.Promise<Void>
    {
        ckDatabaseController.create(.itemZone).map { _ in }
    }
    
    // MARK: - CloudKit Database Controller
    
    var queue: DispatchQueue { ckDatabaseController.queue }
    
    private let ckDatabaseController = CKDatabaseController(scope: .private,
                                                            cacheDirectory: cacheDirectory)
    
    private static var cacheDirectory: URL
    {
        let dir = URL.flowlistDirectory.appendingPathComponent("iCloud Cache")
        FileManager.default.ensureDirectoryExists(dir)
        return dir
    }
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

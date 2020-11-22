import CloudKit
import CloudKid
import SwiftObserver
import SwiftyToolz

/// Flowlist wrapper around CKDatabaseController. Cares for Flowlist specific setup, access and editing of iCloud Database.

class CKRecordDatabase: Observer, Observable
{
    // MARK: - Life Cycle
    
    static let shared = CKRecordDatabase()
    private init() { observeCKDatabaseController() }
    
    // MARK: - Save CKRecords
    
    func save(_ records: [CKRecord]) -> ResultPromise<CKDatabase.SaveResult>
    {
        guard !records.isEmpty else { return .fulfilled(.empty) }
        
        return promise
        {
            ensureAccess()
        }
        .onSuccess
        {
            self.ckDatabaseController.save(records)
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
    
    func deleteCKRecords(with ids: [CKRecord.ID]) -> ResultPromise<CKDatabase.DeletionResult>
    {
        promise
        {
            ensureAccess()
        }
        .onSuccess
        {
            self.ckDatabaseController.deleteCKRecords(with: ids).map { .success($0) }
        }
    }
    
    // MARK: - Fetch Changes
    
    func fetchChanges() -> ResultPromise<CKDatabase.Changes>
    {
        promise
        {
            ensureAccess()
        }
        .onSuccess
        {
            self.ckDatabaseController.fetchChanges(from: .itemZone)
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
    
    private func ensureAccess() -> ResultPromise<Void>
    {
        Promise { accessInitializationResult.whenCached($0.fulfill(_:)) }
    }
    
    private lazy var accessInitializationResult = initializeAccess().cache()
    
    private func initializeAccess() -> ResultPromise<Void>
    {
        promise
        {
            ckDatabaseController.ensureAccountAccess()
        }
        .onSuccess
        {
            self.ensureRecordZoneExists()
        }
        .onSuccess
        {
            self.ensureDatabaseSubscriptionExists()
        }
    }
    
    // MARK: - Observable Database Subscription 
    
    private func ensureDatabaseSubscriptionExists() -> ResultPromise<Void>
    {
        promise
        {
            ckDatabaseController.createDatabaseSubscription(with: .itemSub)
        }
        .mapSuccess
        {
            _ in
        }
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
    
    private func ensureRecordZoneExists() -> ResultPromise<Void>
    {
        ckDatabaseController.create(.itemZone).mapSuccess { _ in }
    }
    
    // MARK: - CloudKit Database Controller
    
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

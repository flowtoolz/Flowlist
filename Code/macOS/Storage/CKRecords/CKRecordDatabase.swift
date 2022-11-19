import CloudKit
import CloudKid
import SwiftObserver
import SwiftyToolz

/// Flowlist wrapper around CKDatabaseController. Cares for Flowlist specific setup, access and editing of iCloud Database.

class CKRecordDatabase: Observer, SwiftObserver.Observable
{
    // MARK: - Life Cycle
    
    static let shared = CKRecordDatabase()
    private init() { observeCKDatabaseController() }
    
    // MARK: - Save CKRecords
    
    func save(_ records: [CKRecord]) async throws -> CKDatabase.SaveResult
    {
        guard !records.isEmpty else { return .empty }
        try await getAccess()
        return try await ckDatabaseController.save(records)
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
    
    func deleteCKRecords(with ids: [CKRecord.ID]) async throws -> CKDatabase.DeletionResult
    {
        try await getAccess()
        return try await ckDatabaseController.deleteCKRecords(with: ids)
    }
    
    // MARK: - Fetch Changes
    
    func fetchChanges() async throws -> CKDatabase.Changes
    {
        try await getAccess()
        return try await ckDatabaseController.fetchChanges(from: .itemZone)
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
    
    private func getAccess() async throws
    {
        try await ckDatabaseController.ensureAccountAccess()
        try await ensureRecordZoneExists()
        try await ensureDatabaseSubscriptionExists()
    }
    
    // MARK: - Observable Database Subscription 
    
    private func ensureDatabaseSubscriptionExists() async throws
    {
        
        _ = try await ckDatabaseController.createDatabaseSubscription(with: .itemSub)
        
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
    
    private func ensureRecordZoneExists() async throws
    {
        _ = try await ckDatabaseController.createZone(withID: .itemZone)
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

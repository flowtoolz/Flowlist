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
    
    func save(_ records: [Record]) -> Promise<Void>
    {
        return save(records.map(CKRecord.init))
    }
    
    func save(_ ckRecords: [CKRecord]) -> Promise<Void>
    {
        return db.save(ckRecords)
    }
    
    func removeRecords(with ids: [String]) -> Promise<Void>
    {
        let ckRecordIDs = ids.map(CKRecord.ID.init(itemID:))
        
        return db.deleteCKRecords(withIDs: ckRecordIDs)
    }
    
    func deleteRecords() -> Promise<Void>
    {
        return db.deleteCKRecords(ofType: CKRecord.itemType, inZone: .item)
    }
    
    // MARK: - Fetch
    
    func fetchChanges() -> Promise<ItemDatabaseChanges>
    {
        return db.fetchChanges(fromZone: .item).map(ItemDatabaseChanges.init)
    }
    
    func fetchItemCKRecords() -> Promise<[CKRecord]>
    {
        return db.fetchCKRecords(ofType: CKRecord.itemType, inZone: .item)
    }
    
    private func fetchSubitemCKRecords(ofItemWithID id: CKRecord.ID) -> Promise<[CKRecord]>
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        let query = CKQuery(recordType: CKRecord.itemType, predicate: predicate)
        
        return db.fetchCKRecords(with: query, inZone: .item)
    }
    
    // MARK: - Ensure Access
    
    func ensureAccess() -> Promise<Void>
    {
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
            .then(on: globalQ)
            {
                self.ensureItemRecordZoneExists()
            }
            .then(on: globalQ)
            {
                self.ensureSubscriptionExists()
            }
            .done(on: globalQ)
            {
                self.didEnsureAccess = true
                resolver.fulfill_()
            }
            .ensure
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
    
    private(set) var didEnsureAccess = false
    var isCheckingAccess: Bool { return ensuringAccessPromise != nil }
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
    
    var globalQ: DispatchQueue { return db.globalQ }
    
    private let db = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = Messenger(ItemDatabaseUpdate.mayHaveChanged)
    typealias Message = ItemDatabaseUpdate
}

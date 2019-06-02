import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemICloudDatabase: Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    init()
    {
        observe(db)
        {
            [weak self] event in self?.didReceive(databaseEvent: event)
        }
    }
    
    private func didReceive(databaseEvent event: ICloudDatabase.Event)
    {
        switch event
        {
        case .didNothing: break
        
        case .didCreateRecord, .didModifyRecord, .didDeleteRecord:
            // TODO: well, maybe go back to using query notifications, since the server change token never seems to actually change!
            log(error: "Don't use query notifications since those pushs don't provide the server change token anyway!")
        
        case .didReceiveDatabaseNotification(let notification):
            didReceive(databaseNotification: notification)
        }
    }
    
    deinit { stopObserving() }
    
    // MARK: - Handle Database Notifications
    
    private func didReceive(databaseNotification: CKDatabaseNotification)
    {
        guard databaseNotification.databaseScope == .private else
        {
            log(error: "Unexpected database scope: \(databaseNotification.databaseScope.rawValue)")
            return
        }
        
        firstly
        {
            fetchChanges()
        }
        .done(on: backgroundQ)
        {
            result in
            
            if result.idsOfDeletedCKRecords.count > 0
            {
                let ids = result.idsOfDeletedCKRecords.map { $0.recordName }
                self.send(.removeItems(withIDs: ids))
            }
            
            if result.changedCKRecords.count > 0
            {
                let records = result.changedCKRecords.map(Record.init)
                self.send(.updateItems(withRecords: records))
            }
        }
        .catch(on: backgroundQ) { log(error: $0.localizedDescription) }
    }
    
    // MARK: - Edit Items
    
    func update(_ records: [Record]) -> Promise<Void>
    {
        var promises = [Promise<Void>]()
        
        let recordsByRootID = records.byRootID
    
        for (rootID, records) in recordsByRootID
        {
            let promise = firstly
            {
                self.update(records, inRootWithID: rootID)
            }
            .then(on: backgroundQ)
            {
                self.fetchChanges()
            }
            .map(on: backgroundQ)
            {
                (result: ChangeFetchResult) -> Void in
                
                if !result.idsOfDeletedCKRecords.isEmpty
                {
                    log(warning: "Unexpected deletions.")
                    
                    let ids = result.idsOfDeletedCKRecords.map
                    {
                        $0.recordName
                    }
                    
                    self.messenger.send(.removeItems(withIDs: ids))
                }
                
                let unexpectedChanges: [CKRecord] = result.changedCKRecords.compactMap
                {
                    guard let rootID = $0.superItem else { return $0 }
                    
                    return recordsByRootID[rootID] == nil ? $0 : nil
                }
                
                if !unexpectedChanges.isEmpty
                {
                    log(warning: "Unexpected changes.")
                    
                    let records = unexpectedChanges.map(Record.init)
                    
                    self.messenger.send(.updateItems(withRecords: records))
                }
                
                return
            }
            
            promises.append(promise)
        }
    
        return when(fulfilled: promises)
    }
    
    private func update(_ records: [Record],
                        inRootWithID rootID: String) -> Promise<Void>
    {
        let rootRecordID = CKRecord.ID(itemID: rootID)
        
        return firstly
        {
            // fetch all records in that root record, including those updated records that already exist and their siblings that are not being updated
            
            fetchSubitemCKRecords(ofItemWithID: rootRecordID)
        }
        .then(on: backgroundQ)
        {
            (allSubitemRecords: [CKRecord]) -> Promise<Void>  in
            
            // if there are no records yet in that root, just save the updated records
            
            guard !allSubitemRecords.isEmpty else
            {
                return self.save(records)
            }
            
            // create hashmap of all subitem records
            
            var subitemRecordsByID = [String : CKRecord]()
            
            allSubitemRecords.forEach
            {
                subitemRecordsByID[$0.recordID.recordName] = $0
            }
            
            // add new records & update existing ones
            
            var recordsToSave = Set<CKRecord>()
            var newRecords = [CKRecord]()
            
            for record in records
            {
                if let existingRecord = subitemRecordsByID[record.id]
                {
                    if existingRecord.apply(record)
                    {
                        recordsToSave.insert(existingRecord)
                    }
                }
                else
                {
                    let newRecord = CKRecord(record: record)
                    
                    recordsToSave.insert(newRecord)
                    newRecords.append(newRecord)
                }
            }
            
            // update positions
            
            let sortedRecords = (allSubitemRecords + newRecords).sorted
            {
                $0.position < $1.position
            }
            
            sortedRecords.forEachIndex
            {
                if $0.position != $1
                {
                    $0.position = $1
                    recordsToSave.insert($0)
                }
            }
            
            // save records back
            
            return self.db.save(Array(recordsToSave))
        }
    }
    
    private func save(_ records: [Record]) -> Promise<Void>
    {
        return save(records.map(CKRecord.init))
    }
    
    func removeRecords(with ids: [String]) -> Promise<Void>
    {
        let ckRecordIDs = ids.map(CKRecord.ID.init(itemID:))
        
        return db.deleteCKRecords(withIDs: ckRecordIDs)
    }
    
    func save(_ records: [CKRecord]) -> Promise<Void>
    {
        return db.save(records)
    }
    
    func deleteRecords() -> Promise<Void>
    {
        return db.deleteCKRecords(ofType: CKRecord.itemType, inZone: .item)
    }
    
    // MARK: - Fetch
    
    func fetchChanges() -> Promise<ChangeFetchResult>
    {
        return db.fetchChanges(fromZone: .item)
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
            .then(on: backgroundQ)
            {
                self.ensureItemRecordZoneExists()
            }
            .then(on: backgroundQ)
            {
                self.ensureSubscriptionExists()
            }
            .done(on: backgroundQ)
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
        
        ensuringAccessPromise = newPromise
        return newPromise
    }
    
    private(set) var didEnsureAccess = false
    var isCheckingAccess: Bool { return ensuringAccessPromise != nil }
    private var ensuringAccessPromise: Promise<Void>?
    
    // MARK: - Create Subscriptions
    
    private func ensureSubscriptionExists() -> Promise<Void>
    {
        return db.createDatabaseSubscription(withID: dbSubID).map { _ in }
    }
    
    private let dbSubID = "ItemDataBaseSubscription"
    
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
    
    private let db = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = Messenger<Edit?>()
    typealias Message = Edit?
    
    // MARK: - Background Queue
    
    var backgroundQ: DispatchQueue
    {
        return DispatchQueue.global(qos: .userInitiated)
    }
}

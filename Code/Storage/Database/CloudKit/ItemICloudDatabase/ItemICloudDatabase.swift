import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemICloudDatabase: Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    init()
    {
        observe(iCloudDatabase)
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
            fetchNewChanges()
        }
        .done(on: backgroundQ)
        {
            result in
            
            if result.idsOfDeletedRecords.count > 0
            {
                let ids = result.idsOfDeletedRecords.map { $0.recordName }
                self.send(.removeItems(withIDs: ids))
            }
            
            if result.changedRecords.count > 0
            {
                let records = result.changedRecords.map(Record.init)
                self.send(.updateItems(withRecords: records))
            }
        }
        .catch(on: backgroundQ) { log(error: $0.localizedDescription) }
    }
    
    // MARK: - Edit Items
    
    func apply(_ edit: Edit) -> Promise<Void>
    {
        switch edit
        {
        case .updateItems(let records):
            
            var promises = [Promise<Void>]()
            
            let recordsByRootID = records.byRootID
            
            for (rootID, records) in recordsByRootID
            {
                let promise = firstly
                {
                    self.updateItems(with: records, inRootWithID: rootID)
                }
                .then(on: backgroundQ)
                {
                    self.fetchNewChanges()
                }
                .map(on: backgroundQ)
                {
                    (result: ChangeFetch.Result) -> Void in
                    
                    if !result.idsOfDeletedRecords.isEmpty
                    {
                        log(warning: "Unexpected deletions.")
                        
                        let ids = result.idsOfDeletedRecords.map
                        {
                            $0.recordName
                        }
                        
                        self.messenger.send(.removeItems(withIDs: ids))
                    }
                    
                    let unexpectedChanges: [CKRecord] = result.changedRecords.compactMap
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
            
        case .removeItems(let ids):
            return firstly
            {
                self.removeItems(with: ids)
            }
            .then(on: backgroundQ)
            {
                self.updateServerChangeToken()
            }
        }
    }
    
    // MARK: - Update Items
    
    private func updateItems(with records: [Record],
                             inRootWithID rootID: String) -> Promise<Void>
    {
        let rootRecordID = CKRecord.ID(itemID: rootID)
        
        return firstly
        {
            fetchSubitemRecords(ofItemWithID: rootRecordID)
        }
        .then(on: backgroundQ)
        {
            (siblingRecords: [CKRecord]) -> Promise<Void>  in
            
            // get sibling records
            
            guard !siblingRecords.isEmpty else
            {
                let records = records.map(CKRecord.init)
                
                return self.iCloudDatabase.save(records)
            }
            
            // create hashmap of sibling records
            
            var siblingRecordsByID = [String : CKRecord]()
            
            siblingRecords.forEach
            {
                siblingRecordsByID[$0.recordID.recordName] = $0
            }
            
            // add new records & update existing ones
            
            var recordsToSave = Set<CKRecord>()
            var newRecords = [CKRecord]()
            
            for record in records
            {
                if let existingRecord = siblingRecordsByID[record.id]
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
            
            let sortedRecords = (siblingRecords + newRecords).sorted
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
            
            return self.iCloudDatabase.save(Array(recordsToSave))
        }
    }
    
    private func fetchSubitemRecords(ofItemWithID id: CKRecord.ID) -> Promise<[CKRecord]>
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        let query = CKQuery(recordType: CKRecord.itemType,
                            predicate: predicate)
        
        return iCloudDatabase.fetchRecords(with: query, inZone: .item)
    }
    
    // MARK: - Remove Items
    
    private func removeItems(with ids: [String]) -> Promise<Void>
    {
        let recordIDs = ids.map(CKRecord.ID.init(itemID:))
        
        return iCloudDatabase.deleteRecords(withIDs: recordIDs)
    }
    
    // MARK: - Reset Items
    
    func reset(tree root: Item) -> Promise<Void>
    {
        let records = root.array.map
        {
            CKRecord(record: $0.makeRecord())
        }
        
        guard !records.isEmpty else { return Promise() }
        
        return Promise<Void>
        {
            resolver in
            
            return firstly
            {
                self.db.deleteRecords(ofType: CKRecord.itemType,
                                      inZone: .item)
            }
            .then(on: backgroundQ)
            {
                self.db.save(records)
            }
            .done(on: backgroundQ)
            {
                resolver.fulfill_()
            }
            .catch(on: backgroundQ)
            {
                resolver.reject($0.storageError)
            }
        }
    }
    
    // MARK: - Fetch
    
    func updateServerChangeToken() -> Promise<Void>
    {
        return fetchNewChanges().map { _ in }
    }
    
    func fetchNewChanges() -> Promise<ChangeFetch.Result>
    {
        return fetchChanges(with: db.serverChangeToken)
    }
    
    func fetchAllChanges() -> Promise<ChangeFetch.Result>
    {
        return fetchChanges(with: nil)
    }
    
    private func fetchChanges(with token: CKServerChangeToken?) -> Promise<ChangeFetch.Result>
    {
        return Promise<ChangeFetch.Result>
        {
            resolver in
            
            firstly
            {
                iCloudDatabase.fetchChanges(fromZone: .item,
                                            oldToken: token)
            }
            .done(on: backgroundQ, resolver.fulfill).catch(on: backgroundQ)
            {
                resolver.reject($0.storageError)
            }
        }
    }
    
    // MARK: - iCloud Database Access
    
    func ensureAccess() -> Promise<Accessibility>
    {
        return Promise<Accessibility>
        {
            resolver in
            
            firstly
            {
                self.iCloudDatabase.ensureAccess()
            }
            .then(on: backgroundQ)
            {
                (accessibility: Accessibility) -> Promise<Accessibility> in
                
                guard case .accessible = accessibility else
                {
                    return Promise.value(accessibility)
                }
                
                return firstly
                {
                    self.ensureItemRecordZoneExists()
                }
                .then(on: self.backgroundQ)
                {
                    self.ensureSubscriptionExists()
                }
                .map(on: self.backgroundQ)
                {
                    _ -> Accessibility in
                    
                    self.isAccessible = true
                    
                    return Accessibility.accessible
                }
            }
            .done(on: backgroundQ, resolver.fulfill).catch(on: backgroundQ)
            {
                self.isAccessible = false
                
                resolver.reject($0.storageError)
            }
        }
    }
    
    var backgroundQ: DispatchQueue
    {
        return DispatchQueue.global(qos: .background)
    }
    
    private(set) var isAccessible: Bool?
    
    // MARK: - Create Subscriptions
    
    private func ensureSubscriptionExists() -> Promise<Void>
    {
        guard subExists.value else { return createSubscription() }
        
        return Promise()
    }
    
    private func createSubscription() -> Promise<Void>
    {
        return db.createDatabasSubscription(withID: dbSubID).tap
        {
            self.subExists.value = $0.isFulfilled
        }
        .map { _ in }
    }
    
    private let dbSubID = "ItemDataBaseSubscription"
    private var subExists = PersistentFlag(key: "itemDBSubExists", default: false)
    
    // MARK: - Create Zone
    
    private func ensureItemRecordZoneExists() -> Promise<Void>
    {
        guard zoneExists.value else { return createZone() }
        
        return Promise()
    }
    
    private func createZone() -> Promise<Void>
    {
        return db.createZone(with: .item).tap
        {
            self.zoneExists.value = $0.isFulfilled
        }
        .map { _ in }
    }
    
    private var zoneExists = PersistentFlag(key: "itemZoneExists", default: false)
    
    // MARK: - iCloud Database
    
    func handlePushNotification(with userInfo: [String : Any])
    {
        iCloudDatabase.handlePushNotification(with: userInfo)
    }
    
    var isReachable: Var<Bool?> { return db.isReachable }
    
    var db: ICloudDatabase { return iCloudDatabase }
    let iCloudDatabase = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = Messenger<Edit?>()
    typealias Message = Edit?
}

extension Error
{
    var storageError: StorageError
    {
        let message = "This issue came up: \(self.localizedDescription)"
        
        return StorageError.message(message)
    }
}

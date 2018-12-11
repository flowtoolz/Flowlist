import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemICloudDatabase: Observer
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
            fetchNewUpdates()
        }
        .done
        {
            result in
            
            if result.idsOfDeletedRecords.count > 0
            {
                let ids = result.idsOfDeletedRecords.map { $0.recordName }
                self.messenger.send(.removeItems(withIDs: ids))
            }
            
            if result.changedRecords.count > 0
            {
                let mods = result.changedRecords.compactMap { $0.modification }
                self.messenger.send(.updateItems(withModifications: mods))
            }
        }
        .catch { log(error: $0.localizedDescription) }
    }
    
    // MARK: - Create Subscriptions
    
    func ensureSubscriptionExists() -> Promise<Void>
    {
        if subExists.value { return Promise() }
        
        return createItemDatabaseSubscription().map { _ in }
    }
    
    private func createItemDatabaseSubscription() -> Promise<CKSubscription>
    {
        return db.createDatabasSubscription(withID: dbSubID).tap
        {
            self.subExists.value = $0.isFulfilled
        }
    }
    
    private let dbSubID = "ItemDataBaseSubscription"
    private var subExists = PersistentFlag(key: "dbSubExists", default: false)
    
    // MARK: - Edit Items
    
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .updateItems(let modifications):
            
            var promises = [Promise<Void>]()
            
            let modsByRootID = modifications.byRootID
            
            for (rootID, mods) in modsByRootID
            {
                let promise = firstly
                {
                    self.updateItems(with: mods, inRootWithID: rootID)
                }
                .then
                {
                    self.fetchNewUpdates()
                }
                .map
                {
                    (result: ChangeFetch.Result) -> Void in
                    
                    if !result.idsOfDeletedRecords.isEmpty
                    {
                        log(error: "Unexpected deletions.")
                        
                        let ids = result.idsOfDeletedRecords.map { $0.recordName }
                        
                        self.messenger.send(.removeItems(withIDs: ids))
                    }
                    
                    let unexpectedChanges: [CKRecord] = result.changedRecords.compactMap
                    {
                        guard let rootID = $0.superItem else { return $0 }
                        
                        return modsByRootID[rootID] == nil ? $0 : nil
                    }
                    
                    if !unexpectedChanges.isEmpty
                    {
                        log(error: "Unexpected changes.")
                        
                        let mods = unexpectedChanges.compactMap { $0.modification }
                        
                        self.messenger.send(.updateItems(withModifications: mods))
                    }
                    
                    return
                }
                
                promises.append(promise)
            }
            
            when(fulfilled: promises).catch
            {
                log(error: $0.localizedDescription)
            }
            
        case .removeItems(let ids):
            firstly
            {
                self.removeItems(with: ids)
            }
            .then
            {
                self.fetchNewUpdates()
            }
            .catch { log(error: $0.localizedDescription) }
        }
    }
    
    // MARK: - Update Items
    
    private func updateItems(with mods: [Modification],
                             inRootWithID rootID: String) -> Promise<Void>
    {
        let rootRecordID = CKRecord.ID(itemID: rootID)
        
        return firstly
        {
            fetchSubitemRecords(ofItemWithID: rootRecordID)
        }
        .then
        {
            (siblingRecords: [CKRecord]) -> Promise<Void>  in
            
            // get sibling records
            
            guard !siblingRecords.isEmpty else
            {
                let records = mods.map(CKRecord.init)
                
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
            
            for mod in mods
            {
                if let existingRecord = siblingRecordsByID[mod.id]
                {
                    if existingRecord.apply(mod)
                    {
                        recordsToSave.insert(existingRecord)
                    }
                }
                else
                {
                    let newRecord = CKRecord(modification: mod)
                    
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
    
    func resetItemTree(with root: Item) -> Promise<Void>
    {
        return firstly
        {
            self.db.deleteRecords(ofType: CKRecord.itemType, inZone: .item)
        }
        .then
        {
            _ -> Promise<Void> in
            
            let records = root.array.map
            {
                CKRecord(modification: $0.modification())
            }
            
            return self.iCloudDatabase.save(records)
        }
    }
    
    // MARK: - Fetch
    
    func fetchNewUpdates() -> Promise<ChangeFetch.Result>
    {
        return iCloudDatabase.fetchUpdates(fromZone: .item)
    }
    
    func fetchAllUpdates() -> Promise<ChangeFetch.Result>
    {
        return iCloudDatabase.fetchUpdates(fromZone: .item, oldToken: nil)
    }
    
    // MARK: - iCloud Database
    
    func handlePushNotification(with userInfo: [String : Any])
    {
        iCloudDatabase.handlePushNotification(with: userInfo)
    }
    
    func checkAccess() -> Promise<Accessibility>
    {
        return firstly
        {
            ensureSubscriptionExists()
        }
        .then
        {
            self.iCloudDatabase.checkAccess()
        }
    }
    
    var isAccessible: Bool? { return db.isAccessible }
    var isReachable: Var<Bool> { return db.isReachable }
    
    private var db: ICloudDatabase { return iCloudDatabase }
    private let iCloudDatabase = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = EditSender()
}

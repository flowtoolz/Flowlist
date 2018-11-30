import CloudKit
import SwiftObserver
import PromiseKit

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
    
    deinit { stopAllObserving() }
    
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
        .catch { log($0) }
    }
    
    // MARK: - Create Subscriptions
    
    func createItemDatabaseSubscription() -> Promise<CKSubscription>
    {
        return db.createDatabasSubscription(withID: "ItemDataBaseSubscription")
    }
    
    // MARK: - Edit Items
    
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .updateItems(let modifications):
            
            var updatesPromise = Promise()
            
            let modsByRootID = modifications.byRootID
            
            for (rootID, mods) in modsByRootID
            {
                updatesPromise = updatesPromise.then
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
            }
            
            updatesPromise.done
            {
                log("applied updates in \(modsByRootID.count) root items")
            }
            .catch
            {
                guard case let cloudKitError as CKError = $0 else
                {
                    log($0)
                    return
                }
                
                switch cloudKitError
                {
                case CKError.networkUnavailable:
                    log(error: "Device offline")
                    
                default:
                    log(error: "CloudKit: \(cloudKitError.localizedDescription)")
                }
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
            .catch { log($0) }
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
    
    func checkAvailability() -> Promise<Availability>
    {
        return iCloudDatabase.checkAvailability()
    }
    
    var isAvailable: Bool? { return iCloudDatabase.isAvailable }
    
    private var db: ICloudDatabase { return iCloudDatabase }
    private let iCloudDatabase = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = EditSender()
}

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
    
    func createItemQuerySubscription() -> Promise<CKSubscription>
    {
        return db.createQuerySubscription(forRecordType: CKRecord.itemType,
                                          desiredKeys: fieldNames)
    }
    
    private let fieldNames = CKRecord.itemFieldNames
    
    // MARK: - Edit Items
    
    func updateItems(with mods: [Modification],
                     inRootWithID rootID: String) -> Promise<Void>
    {
        let superitemID = CKRecord.ID(itemID: rootID)
        
        return firstly
        {
            fetchSubitemRecords(withSuperItemID: superitemID)
        }
        .then
        {
            (siblingRecords: [CKRecord]) -> Promise<Void>  in
            
            // get sibling records
            
            guard !siblingRecords.isEmpty else
            {
                let records = mods.map { CKRecord(modification: $0) }
                
                return self.iCloudDatabase.save(records)
            }
            
            // create hashmap of sibling records
            
            var siblingRecordsByID = [String : CKRecord]()
            
            for record in siblingRecords
            {
                siblingRecordsByID[record.recordID.recordName] = record
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
            
            for position in 0 ..< sortedRecords.count
            {
                let record = sortedRecords[position]
                
                if record.position != position
                {
                    record.position = position
                    recordsToSave.insert(record)
                }
            }
            
            // save records back
            
            return self.iCloudDatabase.save(Array(recordsToSave))
        }
    }
    
    func resetItemTree(with root: Item) -> Promise<Void>
    {
        return firstly
        {
            self.removeItems()
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
    
    func removeItems(with ids: [String]) -> Promise<Void>
    {
        let recordIDs = ids.map { CKRecord.ID(itemID: $0) }
        
        return iCloudDatabase.deleteRecords(withIDs: recordIDs)
    }
    
    private func removeItems() -> Promise<Void>
    {
        return db.deleteRecords(ofType: CKRecord.itemType, inZone: .item)
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
    
    func fetchNewUpdates() -> Promise<ChangeFetch.Result>
    {
        return iCloudDatabase.fetchUpdates(fromZone: .item)
    }
    
    func fetchAllUpdates() -> Promise<ChangeFetch.Result>
    {
        return iCloudDatabase.fetchUpdates(fromZone: .item, oldToken: nil)
    }
    
    private func fetchSubitemRecords(withSuperItemID id: CKRecord.ID) -> Promise<[CKRecord]>
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        return fetchRecords(predicate)
    }
    
    private func fetchRecords(_ predicate: NSPredicate) -> Promise<[CKRecord]>
    {
        let query = CKQuery(recordType: CKRecord.itemType,
                            predicate: predicate)
        
        return fetchRecords(with: query)
    }
    
    private func fetchRecords(with query: CKQuery) -> Promise<[CKRecord]>
    {
        return iCloudDatabase.fetchRecords(with: query, inZone: .item)
    }
    
    private var db: ICloudDatabase { return iCloudDatabase }
    private let iCloudDatabase = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = EditSender()
}

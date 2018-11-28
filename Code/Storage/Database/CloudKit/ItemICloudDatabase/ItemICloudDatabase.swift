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
        
        firstly {
            fetchNewUpdates()
        }.done { result in
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
        }.catch {
            log($0)
        }
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
                     inRootWithID rootID: String,
                     handleSuccess: @escaping (Bool) -> Void)
    {
        let superitemID = CKRecord.ID(itemID: rootID)
        
        fetchSubitemRecords(withSuperItemID: superitemID)
        {
            // get sibling records
            
            guard var siblingRecords = $0 else
            {
                log(error: "Couldn't fetch sibling records.")
                handleSuccess(false)
                return
            }
            
            guard !siblingRecords.isEmpty else
            {
                let records = mods.map { CKRecord(modification: $0) }
                
                firstly {
                    self.iCloudDatabase.save(records)
                }.done { records in
                    handleSuccess(true)
                }.catch {
                    log($0)
                    handleSuccess(false)
                }
                
                return
            }
         
            // create hashmap of sibling records
            
            var siblingRecordsByID = [String : CKRecord]()
            
            for record in siblingRecords
            {
                siblingRecordsByID[record.recordID.recordName] = record
            }
            
            // add new records & update existing ones
            
            var recordsToSave = Set<CKRecord>()
            
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
                    
                    siblingRecords.append(newRecord)
                    recordsToSave.insert(newRecord)
                }
            }
            
            // update positions
            
            siblingRecords.sort { $0.position < $1.position }
            
            for position in 0 ..< siblingRecords.count
            {
                if siblingRecords[position].position != position
                {
                    siblingRecords[position].position = position
                    recordsToSave.insert(siblingRecords[position])
                }
            }
            
            // save records back
            
            firstly {
                self.iCloudDatabase.save(Array(recordsToSave))
            }.done {
                handleSuccess(true)
            }.catch {
                log($0)
                handleSuccess(false)
            }
        }
    }
    
    func removeItems(with ids: [String],
                     handleSuccess: @escaping (Bool) -> Void)
    {
        let recordIDs = ids.map { CKRecord.ID(itemID: $0) }
        
        firstly {
            iCloudDatabase.deleteRecords(withIDs: recordIDs)
        }.done {
            handleSuccess(true)
        }.catch {
            log($0)
            handleSuccess(false)
        }
    }
    
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    {
        firstly {
            db.deleteRecords(ofType: CKRecord.itemType, inZone: .item)
        }.done {
            handleSuccess(true)
        }.catch {
            log($0)
            handleSuccess(false)
        }
    }
    
    func resetItemTree(with root: Item,
                       handleSuccess: @escaping (Bool) -> Void)
    {
        removeItems
        {
            guard $0 else
            {
                log(error: "Couldn't remove records.")
                handleSuccess(false)
                return
            }
            
            let records: [CKRecord] = root.array.map
            {
                CKRecord(modification: $0.modification())
            }
            
            firstly {
                self.iCloudDatabase.save(records)
            }.then { _ in
                self.fetchNewUpdates()
            }.done {_ in 
                handleSuccess(true)
            }.catch { error in
                log(error)
                handleSuccess(false)
            }
        }
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
    
    func fetchSubitemRecords(withSuperItemID id: CKRecord.ID,
                             handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        fetchItemRecords(predicate, handleResult: handleResult)
    }
    
    func fetchItemRecords(_ predicate: NSPredicate,
                          handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let query = CKQuery(recordType: CKRecord.itemType,
                            predicate: predicate)
        
        firstly {
            fetchRecords(with: query)
        }.done {
            handleResult($0)
        }.catch {
            log($0)
            handleResult(nil)
        }
    }
    
    func fetchRecords(with query: CKQuery) -> Promise<[CKRecord]>
    {
        return iCloudDatabase.fetchRecords(with: query, inZone: .item)
    }
    
    private var db: ICloudDatabase { return iCloudDatabase }
    private let iCloudDatabase = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = EditSender()
}

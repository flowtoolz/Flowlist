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
        
        case .didCreateRecord(let id, let notification):
            didCreateRecord(with: id, notification: notification)
        
        case .didModifyRecord(let id, let notification):
            didModifyRecord(with: id, notification: notification)
        
        case .didDeleteRecord(let id):
            didDeleteRecord(with: id)
        
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
    
    // MARK: - Handle Query Notifications
    
    private func didCreateRecord(with id: CKRecord.ID,
                         notification: CKQueryNotification)
    {
        log(error: "Don't use query notifications as the pushs don't provide the server change token anyway!")
        
        /*
        guard hasAllNewFields(notification) else
        {
            fetchRecord(with: id)
            {
                newRecord in
                
                guard let record = newRecord else
                {
                    log(error: "Fetched new record is nil.")
                    return
                }
                
                if let mod = record.modification
                {
                    self.messenger.send(.insertItems(withModifications: [mod],
                                                     inRootWithID: mod.rootID))
                }
            }
            
            return
        }
        
        if let mod = id.makeModification(from: notification)
        {
            messenger.send(.insertItems(withModifications: [mod],
                                        inRootWithID: mod.rootID))
        }
         */
    }
    
    private func didModifyRecord(with id: CKRecord.ID,
                                  notification: CKQueryNotification)
    {
        log(error: "Don't use query notifications as the pushs don't provide the server change token anyway!")
        
        /*
        guard hasAllNewFields(notification) else
        {
            fetchRecord(with: id)
            {
                modifiedRecord in
                
                guard let record = modifiedRecord else
                {
                    log(error: "Fetched modified record is nil.")
                    return
                }
                
                if let modification = record.modification
                {
                    self.messenger.send(.modifyItem(withModification: modification))
                }
            }
            
            return
        }
        
        if let modification = id.makeModification(from: notification)
        {
            messenger.send(.modifyItem(withModification: modification))
        }
         */
    }
    
    private func didDeleteRecord(with id: CKRecord.ID)
    {
        log(error: "Don't use query notifications as the pushs don't provide the server change token anyway!")
        
        // messenger.send(.removeItems(withIDs: [id.recordName]))
    }
    
    private func hasAllNewFields(_ notification: CKQueryNotification) -> Bool
    {
        guard let fields = notification.recordFields else { return false }
        
        return !notification.isPruned || fields.count == fieldNames.count
    }
    
    private func superItemName(from notification: CKQueryNotification) -> String?
    {
        let fieldName = CKRecord.ItemFieldName.superItem.rawValue
        
        return notification.recordFields?[fieldName] as? String
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
    
    func save(_ records: [CKRecord]) -> Promise<Void>
    {
        return iCloudDatabase.save(records)
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
    
    func fetchRecords(with query: CKQuery) -> Promise<[CKRecord]>
    {
        return iCloudDatabase.fetchRecords(with: query, inZone: .item)
    }
    
    private var db: ICloudDatabase { return iCloudDatabase }
    private let iCloudDatabase = ICloudDatabase()
    
    // MARK: - Observability
    
    let messenger = EditSender()
}

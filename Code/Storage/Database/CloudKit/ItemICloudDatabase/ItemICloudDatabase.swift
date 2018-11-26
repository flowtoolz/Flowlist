import CloudKit
import SwiftObserver

class ItemICloudDatabase: ICloudDatabase
{
    // MARK: - Handle Database Notifications
    
    override func didReceive(databaseNotification: CKDatabaseNotification)
    {
        guard databaseNotification.databaseScope == .private else
        {
            log(error: "Unexpected database scope: \(databaseNotification.databaseScope.rawValue)")
            return
        }
        
        updateServerChangeToken(zoneID: CKRecordZone.ID.item,
                                oldToken: serverChangeToken)
        {
            guard let result = $0 else
            {
                log(error: "Could not fetch updates.")
                return
            }
            
            if result.idsOfDeletedRecords.count > 0
            {
                let ids = result.idsOfDeletedRecords.map { $0.recordName }
                self.messenger.send(.removeItems(withIDs: ids))
            }
            
            if result.changedRecords.count > 0
            {
                // TODO: generalize edits so they don't distinguish between modification and creation, since change fetches don't make that distinction anyway
                // TODO: If possible remove rootID from edit since edits must be able to hold item mods from different roots.
                let mods = result.changedRecords.compactMap { $0.modification }
                
                self.messenger.send(.insertItems(withModifications: mods,
                                                 inRootWithID: nil))
            }
        }
    }
    
    // MARK: - Handle Query Notifications
    
    override func didCreateRecord(with id: CKRecord.ID,
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
    
    override func didModifyRecord(with id: CKRecord.ID,
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
    
    override func didDeleteRecord(with id: CKRecord.ID)
    {
        log(error: "Don't use query notifications as the pushs don't provide the server change token anyway!")
        
        // messenger.send(.removeItems(withIDs: [id.recordName]))
    }
    
    // MARK: - Get Data from Query Notification
    
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
    
    func createItemDatabaseSubscription()
    {
        createDatabasSubscription(withID: "ItemDataBaseSubscription")
    }
    
    func createItemQuerySubscription()
    {
        createQuerySubscription(forRecordType: CKRecord.itemType,
                                desiredTags: fieldNames)
    }
    
    private let fieldNames = CKRecord.itemFieldNames
    
    // MARK: - Observability
    
    let messenger = EditSender()
}
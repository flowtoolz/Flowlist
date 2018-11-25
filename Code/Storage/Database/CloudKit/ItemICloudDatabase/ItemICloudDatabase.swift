import CloudKit
import SwiftObserver

class ItemICloudDatabase: ICloudDatabase
{
    // MARK: - Query Subscription Notifications
    
    override func didCreateRecord(with id: CKRecord.ID,
                                  notification: CKQueryNotification)
    {
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
    }
    
    override func didModifyRecord(with id: CKRecord.ID,
                                  notification: CKQueryNotification)
    {
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
    }
    
    override func didDeleteRecord(with id: CKRecord.ID)
    {
        messenger.send(.removeItems(withIDs: [id.recordName]))
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
    
    // MARK: - Database Subscription Notifications
    
    override func didReceive(databaseNotification: CKDatabaseNotification)
    {
        log()
    }
    
    // MARK: - Create Subscriptions
    
    func createItemQuerySubscription()
    {
        createQuerySubscription(forRecordType: CKRecord.itemType,
                                desiredTags: fieldNames)
    }
    
    private let fieldNames = CKRecord.itemFieldNames
    
    func createItemDatabaseSubscription()
    {
        createDatabasSubscription(withID: "ItemDataBaseSuscription")
    }
    
    // MARK: - Observability
    
    let messenger = EditSender()
}

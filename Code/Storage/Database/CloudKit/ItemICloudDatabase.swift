import CloudKit
import SwiftObserver

let itemICloudDatabase = ItemICloudDatabase()

class ItemICloudDatabase: ICloudDatabase
{
    fileprivate override init() {}
    
    // MARK: - Observe Item Creation
    
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
    
    // MARK: - Observe Item Modification
    
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
    
    // MARK: - Observe Item Deletion
    
    override func didDeleteRecord(with id: CKRecord.ID)
    {
        messenger.send(.removeItems(withIDs: [id.recordName]))
    }
    
    // MARK: - Get Data from Notification
    
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
    
    // MARK: - Create Subscription
    
    func createItemRecordSubscription()
    {
        guard #available(OSX 10.12, *) else
        {
            log(error: "Function not available below macOS 10.12")
            return
        }
        
        let alertKey = "Items were changed in iCloud."
        
        createSubscription(forRecordType: CKRecord.itemType,
                           desiredTags: fieldNames,
                           alertLocalizationKey: alertKey)
    }
    
    private let fieldNames = CKRecord.itemFieldNames
    
    // MARK: - Observability
    
    let messenger = DatabaseMessenger()
}

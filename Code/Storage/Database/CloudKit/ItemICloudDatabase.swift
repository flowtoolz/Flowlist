import CloudKit
import SwiftObserver
import SwiftyToolz

let itemICloudDatabase = ItemICloudDatabase()

class ItemICloudDatabase: ICloudDatabase, Observable
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
                    self.didCreateRecord(with: mod,
                                         superItemName: record.superItem)
                }
            }
            
            return
        }
        
        if let mod = id.makeModification(from: notification)
        {
            didCreateRecord(with: mod,
                            superItemName: superItemName(from: notification))
        }
    }
    
    private func didCreateRecord(with mod: Modification, superItemName: String?)
    {
        send(.insertItems([mod], inItemWithId: superItemName))
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
                    self.didModifyRecord(with: modification,
                                         superItemName: record.superItem)
                }
            }
            
            return
        }
        
        if let modification = id.makeModification(from: notification)
        {
            didModifyRecord(with: modification,
                            superItemName: superItemName(from: notification))
        }
    }
    
    private func didModifyRecord(with mod: Modification, superItemName: String?)
    {
        send(.modifyItem(mod, inItemWithId: superItemName))
    }
    
    // MARK: - Observe Item Deletion
    
    override func didDeleteRecord(with id: CKRecord.ID)
    {
        send(.removeItemsWithIds([id.recordName]))
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
    
    // MARK: - Create Item Subscription
    
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
    
    var latestUpdate: Edit? = nil
}

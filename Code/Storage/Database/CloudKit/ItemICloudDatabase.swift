import CloudKit
import SwiftObserver
import SwiftyToolz

let itemICloudDatabase = ItemICloudDatabase()

class ItemICloudDatabase: ICloudDatabase, Observable
{
    fileprivate override init() {}
    
    // MARK: - Observe Item Records
    
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
                    self.didCreateRecord(with: mod)
                }
            }
            
            return
        }
        
        if let mod = id.makeModification(from: notification)
        {
            didCreateRecord(with: mod)
        }
    }
    
    private func didCreateRecord(with mod: Modification)
    {
        if let rootID = mod.rootId
        {
            send(.insertItems([mod], inItemWithId: rootID))
        }
        else
        {
            // TODO: ...
            log(error: "Root was created in iCloud. This case is not being handled.")
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
                    self.didModifyRecord(with: modification,
                                         superItemName: record.superItem)
                }
            }
            
            return
        }
        
        let superItemFieldName = CKRecord.FieldName.superItem.rawValue
        let fields = notification.recordFields
        let superItemName = fields?[superItemFieldName] as? String
        
        if let modification = id.makeModification(from: notification)
        {
            didModifyRecord(with: modification, superItemName: superItemName)
        }
    }
    
    private func didModifyRecord(with mod: Modification, superItemName: String?)
    {
        send(.modifyItem(mod, inItemWithId: superItemName))
    }
    
    override func didDeleteRecord(with id: CKRecord.ID)
    {
        send(.removeItemsWithIds([id.recordName]))
    }
    
    private func hasAllNewFields(_ notification: CKQueryNotification) -> Bool
    {
        guard let fields = notification.recordFields else { return false }
        
        return !notification.isPruned || fields.count == fieldNames.count
    }
    
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

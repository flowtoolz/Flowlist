import CloudKit
import SwiftObserver
import SwiftyToolz

extension ItemEditInfo
{
    init?(from record: CKRecord)
    {
        guard record.recordType == "Item" else
        {
            log(error: "iCloud record type is \"\(record.recordType)\". Expected\"Item\".")
            
            return nil
        }
        
        var newRootId: String?
        
        let superItemString = ItemStorageField.ICloudName.superItem.rawValue
        
        if let superItemRef: CKReference = record[superItemString]
        {
            newRootId = superItemRef.recordID.recordName
        }
        
        self.init(id: record.recordID.recordName,
                  text: record.text,
                  state: record.state,
                  tag: record.tag,
                  rootId: newRootId)
    }
    
    init?(with id: CKRecordID, notificationFields: JSON)
    {
        var modifiedFields = [ItemStorageField]()
        var newRootId: String?
        var newText: String?
        var newState: ItemData.State?
        var newTag: ItemData.Tag?
        
        for (nameValue, value) in notificationFields
        {
            guard let name = ItemStorageField.ICloudName(rawValue: nameValue) else
            {
                log(error: "Unknown item database field name: \(nameValue)")
                return nil
            }
            
            let field = ItemStorageField(from: name)
            
            switch field
            {
            case .text: newText = value as? String
            case .state: newState = ItemData.State(from: value as? Int)
            case .tag: newTag = ItemData.Tag(from: value as? Int)
            case .root: newRootId = value as? String
            }
            
            modifiedFields.append(field)
        }
        
        self.init(id: id.recordName,
                  text: newText,
                  state: newState,
                  tag: newTag,
                  rootId: newRootId,
                  modified: modifiedFields)
    }
}



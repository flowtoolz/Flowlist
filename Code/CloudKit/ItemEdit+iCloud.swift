import CloudKit

extension ItemEditInfo
{
    init?(from record: CKRecord)
    {
        guard record.isItem else { return nil }
        
        self.init(id: record.recordID.recordName,
                  text: record.text,
                  state: record.state,
                  tag: record.tag,
                  rootId: record.superItem)
    }
    
    init?(with id: CKRecordID, notificationFields: [String : Any])
    {
        var modifiedFields = [ItemStorageField]()
        var newRootId: String?
        var newText: String?
        var newState: ItemData.State?
        var newTag: ItemData.Tag?
        
        for (name, value) in notificationFields
        {
            guard let field = CKRecord.field(for: name) else { return nil }
            
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

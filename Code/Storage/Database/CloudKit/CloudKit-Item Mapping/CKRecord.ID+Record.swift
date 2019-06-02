import CloudKit
import SwiftObserver

extension CKRecord.ID
{
    func makeRecord(from notificaton: CKQueryNotification) -> Record?
    {
        guard let fields = notificaton.recordFields else { return nil }
        
        var newRootID: String?
        var newPosition: Int?
        var newText: String?
        var newState: ItemData.State?
        var newTag: ItemData.Tag?
        
        for (name, value) in fields
        {
            guard let field = CKRecord.recordField(forFieldName: name) else
            {
                continue
            }
            
            switch field
            {
            case .text: newText = value as? String
            case .state: newState = ItemData.State(integer: value as? Int)
            case .tag: newTag = ItemData.Tag(integer: value as? Int)
            case .root: newRootID = value as? String
            case .position: newPosition = value as? Int
            }
        }
        
        return Record(id: recordName,
                      text: newText,
                      state: newState,
                      tag: newTag,
                      rootID: newRootID,
                      position: newPosition ?? 0)
    }
    
    convenience init(itemID: String)
    {
        self.init(recordName: itemID, zoneID: .item)
    }
}
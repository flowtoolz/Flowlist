import CloudKit
import SwiftObserver

extension CKRecord.ID
{
    func makeModification(from notificaton: CKQueryNotification) -> Modification?
    {
        guard let fields = notificaton.recordFields else { return nil }
        
        var newPosition: Int?
        var newText: String?
        var newState: ItemData.State?
        var newTag: ItemData.Tag?
        
        for (name, value) in fields
        {
            guard let field = CKRecord.modificationField(forItemFieldName: name) else { continue }
            
            switch field
            {
            case .text: newText = value as? String
            case .state: newState = ItemData.State(integer: value as? Int)
            case .tag: newTag = ItemData.Tag(integer: value as? Int)
            case .position: newPosition = value as? Int
            }
        }
        
        return Modification(id: recordName,
                            text: newText,
                            state: newState,
                            tag: newTag,
                            position: newPosition)
    }
}

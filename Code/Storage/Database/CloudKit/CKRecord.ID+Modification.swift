import CloudKit
import SwiftObserver

extension CKRecord.ID
{
    func makeModification(from notificaton: CKQueryNotification) -> Modification?
    {
        guard let fields = notificaton.recordFields else { return nil }
        
        var newRootId: String?
        var newPosition: Int?
        var newText: String?
        var newState: ItemData.State?
        var newTag: ItemData.Tag?
        
        for (name, value) in fields
        {
            guard let field = CKRecord.field(for: name) else
            {
                log(error: "Could not create modification from record id \(recordName) and notification field \(fields.debugDescription).")
                return nil
            }
            
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

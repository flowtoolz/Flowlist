import CloudKit
import SwiftObserver

extension CKRecord.ID
{
    func makeModification(from notificaton: CKQueryNotification) -> Modification?
    {
        guard let fields = notificaton.recordFields else { return nil }
        
        var modifiedFields = [Modification.Field]()
        var newRootId: String?
        var newPosition: Int?
        var newText: String?
        var newState: ItemData.State?
        var newTag: ItemData.Tag?
        
        for (name, value) in fields
        {
            guard let field = CKRecord.field(for: name) else
            {
                log(error: "Could not create modification from record id \(recordName) and notification fields \(fields.debugDescription).")
                return nil
            }
            
            switch field
            {
            case .text: newText = value as? String
            case .state: newState = ItemData.State(from: value as? Int)
            case .tag: newTag = ItemData.Tag(from: value as? Int)
            case .root: newRootId = value as? String
            case .position: newPosition = value as? Int
            }
            
            modifiedFields.append(field)
        }
        
        return Modification(id: recordName,
                            text: newText,
                            state: newState,
                            tag: newTag,
                            rootId: newRootId,
                            position: newPosition,
                            modified: modifiedFields)
    }
}

import CloudKit
import SwiftObserver
import SwiftyToolz

extension CKRecord
{
    // MARK: - Convert to Record
    
    func makeRecord() -> Record
    {
        if recordType != .itemType
        {
            log(warning: "Attempting to make item record from a CKRecord of type \(recordType). Excpected type \(CKRecord.RecordType.itemType)")
        }
        
        return Record(id: recordID.recordName,
                      text: text,
                      state: state,
                      tag: tag,
                      parent: superItem,
                      position: position ?? 0)
    }
    
    // MARK: - Storage Properties
    
    var text: String?
    {
        get
        {
            guard isItem else { return nil }
            return self[ItemFieldName.text.rawValue]
        }
        
        set
        {
            guard isItem else { return }
            self[ItemFieldName.text.rawValue] = newValue
        }
    }
    
    var state: ItemData.State?
    {
        get
        {
            guard isItem else { return nil }
            
            let stateInt: Int? = self[ItemFieldName.state.rawValue]
            
            return ItemData.State(integer: stateInt)
        }
        
        set
        {
            guard isItem else { return }
            
            let stateInt = newValue?.rawValue
            
            self[ItemFieldName.state.rawValue] = stateInt
        }
    }
    
    var tag: ItemData.Tag?
    {
        get
        {
            guard isItem else { return nil }
            
            let tagInt: Int? = self[ItemFieldName.tag.rawValue]
            
            return ItemData.Tag(integer: tagInt)
        }
        
        set
        {
            guard isItem else { return }
            
            let tagInt = newValue?.rawValue
            
            self[ItemFieldName.tag.rawValue] = tagInt
        }
    }
    
    var superItem: Record.ID?
    {
        get
        {
            guard isItem else { return nil }
            
            let fieldName = ItemFieldName.superItem.rawValue
            
            guard let reference: Reference = self[fieldName] else
            {
                return nil
            }
            
            return reference.recordID.recordName
        }
        
        set
        {
            guard isItem else { return }
            
            let fieldName = ItemFieldName.superItem.rawValue
            
            guard let newValue = newValue else
            {
                self[fieldName] = nil
                return
            }
            
            self[fieldName] = Reference(parent: newValue)
        }
    }
    
    var position: Int?
    {
        get
        {
            guard isItem else { return nil }
            return self[ItemFieldName.position.rawValue]
        }
        
        set
        {
            guard isItem else { return }
            self[ItemFieldName.position.rawValue] = newValue
        }
    }
    
    // MARK: - Type
    
    var isItem: Bool
    {
        let result = recordType == .itemType
        
        if !result
        {
            log(warning: "Type is \"\(recordType)\" but expected \"\(CKRecord.RecordType.itemType)\".")
        }
        
        return result
    }
    
    // MARK: - Fields
    
    private enum ItemFieldName: String
    {
        case text, state, tag, superItem, position
    }
}

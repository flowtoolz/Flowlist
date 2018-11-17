import CloudKit
import SwiftObserver

extension CKRecord
{
    // MARK: - Initialization

    convenience init(modification: Modification, superItem: String?)
    {
        self.init(recordType: CKRecord.itemType,
                  recordID: ID(recordName: modification.id))
        
        apply(modification)
        
        self.superItem = superItem
    }
    
    @discardableResult
    func apply(_ modification: Modification) -> Bool
    {
        var didChange = false
        
        if text != modification.text
        {
            text = modification.text
            didChange = true
        }
        
        if state != modification.state
        {
            state = modification.state
            didChange = true
        }
        
        if tag != modification.tag
        {
            tag = modification.tag
            didChange = true
        }
        
        if position != modification.position
        {
            position = modification.position
            didChange = true
        }
        
        return didChange
    }
    
    // MARK: - Mofification
    
    var modification: Modification?
    {
        guard isItem else
        {
            log(error: "Could not create modification from record.")
            return nil
        }
        
        return Modification(id: recordID.recordName,
                            text: text,
                            state: state,
                            tag: tag,
                            rootID: superItem,
                            position: position)
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
    
    var superItem: String?
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
            
            self[fieldName] = Reference(ownerName: newValue)
        }
    }
    
    var position: Int
    {
        get
        {
            guard isItem else { return 0 }
            return self[ItemFieldName.position.rawValue] ?? 0
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
        let result = recordType == CKRecord.itemType
        
        if !result
        {
            log(warning: "Type is \"\(recordType)\" but expected \"\(CKRecord.itemType)\".")
        }
        
        return result
    }
    
    static var itemType: String { return "Item" }
    
    // MARK: - Fields
    
    static var itemFieldNames: [String]
    {
        return ItemFieldName.allCases.map { $0.rawValue }
    }
    
    static func modificationField(forFieldName name: String) -> Modification.Field?
    {
        guard let itemFieldName = ItemFieldName(rawValue: name) else
        {
            log(error: "Unknown item record field name: \(name)")
            return nil
        }
        
        return itemFieldName.modificationField
    }
    
    enum ItemFieldName: String, CaseIterable
    {
        var modificationField: Modification.Field
        {
            switch self
            {
            case .text: return .text
            case .state: return .state
            case .tag: return .tag
            case .position: return .position
            case .superItem: return .root
            }
        }
        
        case text, state, tag, superItem, position
    }
}

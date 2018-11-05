import CloudKit
import SwiftObserver

extension CKRecord
{
    // MARK: - Initialization
    
    convenience init(from modification: Item.Modification)
    {
        self.init(recordType: CKRecord.itemType,
                  recordID: ID(recordName: modification.id))
        
        text = modification.text
        state = modification.state
        tag = modification.tag
        superItem = modification.rootId
    }
    
    // MARK: - Mofification
    
    var modification: Item.Modification?
    {
        guard isItem else
        {
            log(error: "Could not create modification from record.")
            return nil
        }
        
        return Item.Modification(id: recordID.recordName,
                                 text: text,
                                 state: state,
                                 tag: tag,
                                 rootId: superItem)
    }
    
    // MARK: - Storage Properties
    
    var text: String?
    {
        get
        {
            guard isItem else { return nil }
            return self[FieldName.text.rawValue]
        }
        
        set
        {
            guard isItem else { return }
            self[FieldName.text.rawValue] = newValue
        }
    }
    
    var state: ItemData.State?
    {
        get
        {
            guard isItem else { return nil }
            
            let stateInt: Int? = self[FieldName.state.rawValue]
            
            return ItemData.State(from: stateInt)
        }
        
        set
        {
            guard isItem else { return }
            
            let stateInt = newValue?.rawValue
            
            self[FieldName.state.rawValue] = stateInt
        }
    }
    
    var tag: ItemData.Tag?
    {
        get
        {
            guard isItem else { return nil }
            
            let tagInt: Int? = self[FieldName.tag.rawValue]
            
            return ItemData.Tag(from: tagInt)
        }
        
        set
        {
            guard isItem else { return }
            
            let tagInt = newValue?.rawValue
            
            self[FieldName.tag.rawValue] = tagInt
        }
    }
    
    var superItem: String?
    {
        get
        {
            guard isItem else { return nil }
            
            let fieldName = FieldName.superItem.rawValue
            
            guard let reference: Reference = self[fieldName] else
            {
                return nil
            }
            
            return reference.recordID.recordName
        }
        
        set
        {
            guard isItem else { return }
            
            let fieldName = FieldName.superItem.rawValue
            
            guard let newValue = newValue else
            {
                self[fieldName] = nil
                return
            }
            
            self[fieldName] = Reference(ownerName: newValue)
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
    
    static var fieldNames: [String]
    {
        return Item.Field.allCases.map { FieldName(from: $0).rawValue }
    }
    
    static func field(for name: String) -> Item.Field?
    {
        guard let recordField = FieldName(rawValue: name) else
        {
            log(error: "Unknown item record field name: \(name)")
            return nil
        }
        
        return recordField.itemField
    }
    
    private enum FieldName: String
    {
        init(from itemField: Item.Field)
        {
            switch itemField
            {
            case .text: self = .text
            case .state: self = .state
            case .tag: self = .tag
            case .root: self = .superItem
            }
        }
        
        var itemField: Item.Field
        {
            switch self
            {
            case .text: return .text
            case .state: return .state
            case .tag: return .tag
            case .superItem: return .root
            }
        }
        
        case text, state, tag, superItem
    }
}

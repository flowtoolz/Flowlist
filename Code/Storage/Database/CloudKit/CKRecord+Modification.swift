import CloudKit
import SwiftObserver

extension CKRecord
{
    // MARK: - Initialization

    convenience init(modification: Modification)
    {
        self.init(recordType: CKRecord.itemType,
                  recordID: ID(recordName: modification.id))
        
        apply(modification)
    }
    
    @discardableResult
    func apply(_ modification: Modification) -> Bool
    {
        var didChange = false
        
        for field in modification.modified
        {
            switch field
            {
            case .text:
                guard text != modification.text else { continue }
                text = modification.text
            case .state:
                guard state != modification.state else { continue }
                state = modification.state
            case .tag:
                guard tag != modification.tag else { continue }
                tag = modification.tag
            case .root:
                guard superItem != modification.rootId else { continue }
                superItem = modification.rootId
            case .position:
                guard position != modification.position else { continue }
                position = modification.position
            }
            
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
            
            return ItemData.State(integer: stateInt)
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
            
            return ItemData.Tag(integer: tagInt)
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
    
    var position: Int?
    {
        get
        {
            guard isItem else { return nil }
            return self[FieldName.position.rawValue]
        }
        
        set
        {
            guard isItem else { return }
            self[FieldName.position.rawValue] = newValue
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
        return Modification.Field.allCases.map { FieldName($0).rawValue }
    }
    
    static func field(for name: String) -> Modification.Field?
    {
        guard let fieldName = FieldName(rawValue: name) else
        {
            log(error: "Unknown item record field name: \(name)")
            return nil
        }
        
        return fieldName.field
    }
    
    private enum FieldName: String
    {
        init(_ field: Modification.Field)
        {
            switch field
            {
            case .text: self = .text
            case .state: self = .state
            case .tag: self = .tag
            case .root: self = .superItem
            case .position: self = .position
            }
        }
        
        var field: Modification.Field
        {
            switch self
            {
            case .text: return .text
            case .state: return .state
            case .tag: return .tag
            case .superItem: return .root
            case .position: return .position
            }
        }
        
        case text, state, tag, superItem, position
    }
}

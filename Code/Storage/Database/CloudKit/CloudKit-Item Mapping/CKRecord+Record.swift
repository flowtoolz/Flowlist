import CloudKit
import SwiftObserver
import SwiftyToolz

extension CKRecord
{
    // MARK: - Initialization

    convenience init(record: Record)
    {
        self.init(recordType: CKRecord.itemType,
                  recordID: ID(itemID: record.id))

        apply(record)
    }
    
    @discardableResult
    func apply(_ record: Record) -> Bool
    {
        var didChange = false
        
        if text != record.text
        {
            text = record.text
            didChange = true
        }
        
        if state != record.state
        {
            state = record.state
            didChange = true
        }
        
        if tag != record.tag
        {
            tag = record.tag
            didChange = true
        }
        
        if superItem != record.rootID
        {
            superItem = record.rootID
            didChange = true
        }
        
        if position != record.position
        {
            position = record.position
            didChange = true
        }
        
        return didChange
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
            
            self[fieldName] = Reference(itemOwnerName: newValue)
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
    
    static var itemType: RecordType { return "Item" }
    
    // MARK: - Fields
    
    static var itemFieldNames: [String]
    {
        return ItemFieldName.allCases.map { $0.rawValue }
    }
    
    static func recordField(forFieldName name: String) -> Record.Field?
    {
        guard let itemFieldName = ItemFieldName(rawValue: name) else
        {
            log(error: "Unknown item record field name: \(name)")
            return nil
        }
        
        return itemFieldName.recordField
    }
    
    enum ItemFieldName: String, CaseIterable
    {
        var recordField: Record.Field
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

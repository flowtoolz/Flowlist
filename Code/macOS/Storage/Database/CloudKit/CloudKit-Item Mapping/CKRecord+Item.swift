import CloudKit
import SwiftObserver
import SwiftyToolz

extension CKRecord
{
    // MARK: - Convert between CKRecord and Record

    convenience init(record: Record)
    {
        self.init(recordType: .item, recordID: ID(itemID: record.id))

        text = record.text
        state = record.state
        tag = record.tag
        superItem = record.rootID
        position = record.position
    }
    
    func makeItemRecord() -> Record
    {
        return Record(id: recordID.recordName,
                      text: text,
                      state: state,
                      tag: tag,
                      rootID: superItem,
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
        let result = recordType == .item
        
        if !result
        {
            log(warning: "Type is \"\(recordType)\" but expected \"\(CKRecord.RecordType.item)\".")
        }
        
        return result
    }
    
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

extension CKRecord.RecordType
{
    static var item: CKRecord.RecordType { return "Item" }
}

extension CKRecord.ID
{
    convenience init(itemID: String)
    {
        self.init(recordName: itemID, zoneID: .item)
    }
}

extension CKRecord.Reference
{
    // TODO: start using CKRecord.parent reference property in addition so we can migrate to that property at some point
    convenience init(itemOwnerName: String)
    {
        self.init(recordID: CKRecord.ID(itemID: itemOwnerName),
                  action: .deleteSelf)
    }
}

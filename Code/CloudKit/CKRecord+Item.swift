import CloudKit
import SwiftObserver

extension CKRecord
{
    // MARK: - Initialization
    
    convenience init?(from item: Item)
    {
        guard let data = item.data else
        {
            log(error: "Item has no data.")
            return nil
        }
        
        self.init(recordType: CKRecord.itemType,
                  recordID: CKRecordID(recordName: data.id))
        
        text = item.text
        state = data.state.value
        tag = data.tag.value
        superItem = item.root?.data?.id
    }
    
    // MARK: - Item Storage Properties
    
    var text: String?
    {
        get
        {
            guard isItem else { return nil }
            return self[ItemStorageField.text.iCloudName.rawValue]
        }
        
        set
        {
            guard isItem else { return }
            self[ItemStorageField.text.iCloudName.rawValue] = newValue
        }
    }
    
    var state: ItemData.State?
    {
        get
        {
            guard isItem else { return nil }
            
            let stateInt: Int? = self[ItemStorageField.state.iCloudName.rawValue]
            
            return ItemData.State(from: stateInt)
        }
        
        set
        {
            guard isItem else { return }
            
            let stateInt = newValue?.rawValue
            
            self[ItemStorageField.state.iCloudName.rawValue] = stateInt
        }
    }
    
    var tag: ItemData.Tag?
    {
        get
        {
            guard isItem else { return nil }
            
            let tagInt: Int? = self[ItemStorageField.tag.iCloudName.rawValue]
            
            return ItemData.Tag(from: tagInt)
        }
        
        set
        {
            guard isItem else { return }
            
            let tagInt = newValue?.rawValue
            
            self[ItemStorageField.tag.iCloudName.rawValue] = tagInt
        }
    }
    
    var superItem: String?
    {
        get
        {
            guard isItem else { return nil }
            
            let fieldName = ItemStorageField.ICloudName.superItem.rawValue
            
            guard let reference: CKReference = self[fieldName] else
            {
                return nil
            }
            
            return reference.recordID.recordName
        }
        
        set
        {
            guard isItem else { return }
            
            let fieldName = ItemStorageField.ICloudName.superItem.rawValue
            
            guard let newValue = newValue else
            {
                self[fieldName] = nil
                return
            }
            
            self[fieldName] = CKReference(toOwner: newValue)
        }
    }
    
    // MARK: - Type
    
    var isItem: Bool
    {
        let result = recordType == CKRecord.itemType
        
        if !result { log(warning: "CKRecord is not an item record.") }
        
        return result
    }
    
    static var itemType: String { return "Item" }
    
    // MARK: - Fields
    
    static var fieldNames: [String]
    {
        return ItemStorageField.all.map { $0.iCloudName.rawValue }
    }
    
    static func field(for name: String) -> ItemStorageField?
    {
        return ItemStorageField(fromRecordField: name)
    }
}

fileprivate extension ItemStorageField
{
    init?(fromRecordField recordField: String)
    {
        guard let iCloudName = ICloudName(rawValue: recordField) else
        {
            log(error: "Unknown item record field name: \(recordField)")
            return nil
        }
        
        self = ItemStorageField(from: iCloudName)
    }
    
    init(from iCloudName: ICloudName)
    {
        switch iCloudName
        {
        case .text: self = .text
        case .state: self = .state
        case .tag: self = .tag
        case .superItem: self = .root
        }
    }
    
    var iCloudName: ICloudName
    {
        switch self
        {
        case .text: return .text
        case .state: return .state
        case .tag: return .tag
        case .root: return .superItem
        }
    }
    
    enum ICloudName: String
    {
        case text, state, tag, superItem
    }
}

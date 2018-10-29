import CloudKit
import SwiftObserver
import SwiftyToolz

extension ItemDatabaseUpdateInfo
{
    init?(from record: CKRecord)
    {
        guard let data = ItemData(from: record) else
        {
            log(error: "Could not create item data from record.")
            return nil
        }
        
        var newRootId: String?
        
        let superItemString = ItemDatabaseField.ICloudName.superItem.rawValue
        
        if let superItemRef: CKReference = record[superItemString]
        {
            newRootId = superItemRef.recordID.recordName
        }
        
        self.init(data: data, rootId: newRootId)
    }
    
    init?(with id: CKRecordID, notificationFields: JSON)
    {
        var fields = [ItemDatabaseField]()
        let data = ItemData(id: id.recordName)
        var newRootId: String?
        
        for (nameValue, value) in notificationFields
        {
            guard let name = ItemDatabaseField.ICloudName(rawValue: nameValue) else
            {
                log(error: "Unknown item database field name: \(nameValue)")
                return nil
            }
            
            let field = ItemDatabaseField(from: name)
            
            switch field
            {
            case .text:
                guard let text = value as? String else
                {
                    log(error: "Couldn't cast value of field \(nameValue) to String.")
                    return nil
                }
                
                data.text <- text
            case .state:
                guard let stateInt = value as? Int else
                {
                    log(error: "Couldn't cast value of field \(nameValue) to Int.")
                    return nil
                }
                
                guard let state = ItemData.State(rawValue: stateInt) else
                {
                    log(error: "Couldn't create item state from number \(stateInt).")
                    return nil
                }
                
                data.state <- state
            case .tag:
                guard let tagInt = value as? Int else
                {
                    log(error: "Couldn't cast value of field \(nameValue) to Int.")
                    return nil
                }
                
                guard let tag = ItemData.Tag(rawValue: tagInt) else
                {
                    log(error: "Couldn't create item tag from number \(tagInt).")
                    return nil
                }
                
                data.tag <- tag
            case .root:
                guard let superItemRef = value as? CKReference else
                {
                    log(error: "Couldn't cast value of field \(nameValue) to CKReference.")
                    return nil
                }
                
                newRootId = superItemRef.recordID.recordName
            }
            
            fields.append(field)
        }
        
        self.init(data: data, rootId: newRootId, modified: fields)
    }
}

extension ItemDatabaseField
{
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

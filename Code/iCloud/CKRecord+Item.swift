import CloudKit
import SwiftyToolz

extension CKRecord
{
    convenience init?(from item: Item)
    {
        guard let data = item.data else
        {
            log(error: "Item has no data.")
            return nil
        }
        
        self.init(recordType: "Item",
                  recordID: CKRecordID(recordName: data.id))
        
        self["text"] = item.text
        self["state"] = data.state.value?.rawValue
        self["tag"] = data.tag.value?.rawValue
        
        if let rootData = item.root?.data
        {
            let superItemId = CKRecordID(recordName: rootData.id)
            self["superItem"] = superItemId.ownerReference
        }
    }
}

extension CKRecordID
{
    var ownerReference: CKReference
    {
        return CKReference(recordID: self, action: .deleteSelf)
    }
}

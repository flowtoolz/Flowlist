import CloudKit
import SwiftObserver

extension Tree where Data == ItemData
{
    convenience init?(records: [CKRecord])
    {
        // create unconnected items. remember associated records.
        
        var hashMap = [String : (CKRecord, Item)]()
        
        for record in records
        {
            guard let modification = record.modification else { continue }
            
            let id = modification.id
            
            hashMap[id] = (record, Item(modification: modification))
        }
        
        // connect items. find root.
        
        var root: Item?
        
        for (record, item) in hashMap.values
        {
            guard let superItemId = record.superItem else
            {
                if root != nil
                {
                    log(error: "Record array contains more than 1 root.")
                    return nil
                }
                
                root = item
                
                continue
            }
            
            guard let (_, superItem) = hashMap[superItemId] else
            {
                log(error: "Record for superitem with id \(superItemId) is missing.")
                return nil
            }
            
            item.root = superItem
            
            superItem.add(item)
        }
        
        guard let nonOptionalRoot = root else
        {
            log(error: "Record array contains no root.")
            return nil
        }
        
        // sort root
        
        nonOptionalRoot.sortWithoutSendingUpdate
        {
            let leftPosition = hashMap[$0.data.id]?.0.position ?? 0
            let rightPosition = hashMap[$1.data.id]?.0.position ?? 0
            
            return leftPosition < rightPosition
        }
        
        // init with data of root
        
        self.init(data: nonOptionalRoot.data,
                  root: nil,
                  numberOfLeafs: nonOptionalRoot.numberOfLeafs)
        
        insert(nonOptionalRoot.branches, at: 0)
    }
}

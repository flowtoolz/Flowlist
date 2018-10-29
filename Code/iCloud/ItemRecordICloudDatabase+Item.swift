import CloudKit
import SwiftObserver
import SwiftyToolz

extension ItemRecordICloudDatabase
{
    // MARK: - Save Item Tree to iCloud
    
    private func save(itemTree root: Item)
    {
        let itemRecords = records(fromItemTree: root)
        
        save(itemRecords)
    }
    
    private func records(fromItemTree root: Item) -> [CKRecord]
    {
        var result = [CKRecord]()
        
        if let record = CKRecord(from: root)
        {
            result.append(record)
        }
        
        for subitem in root.branches
        {
            result.append(contentsOf: records(fromItemTree: subitem))
        }
        
        return result
    }
    
    // MARK: - Fetch & Connect Items
    
    private func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    {
        fetchItemRecords()
        {
            records in receiveRoot(self.itemTree(from: records))
        }
    }
    
    private func itemTree(from records: [CKRecord]?) -> Item?
    {
        // get record array
        
        guard let records = records else
        {
            log(warning: "Record array is nil.")
            
            return nil
        }
        
        // create unconnected items. remember associated records.
        
        var hashMap = [String : (CKRecord, Item)]()
        
        for record in records
        {
            guard let data = ItemData(from: record) else { continue }
            
            hashMap[data.id] = (record, Item(data: data))
        }
        
        // connect items. find root.
        
        var root: Item?
        
        for (record, item) in hashMap.values
        {
            guard let superItemReference: CKReference = record["superItem"] else
            {
                if root != nil
                {
                    log(error: "Record array contains more than 1 root.")
                    
                    return nil
                }
                
                root = item
                
                continue
            }
            
            let superItemId = superItemReference.recordID.recordName
            
            guard let (_, superItem) = hashMap[superItemId] else
            {
                log(error: "Record for super item with id \(superItemId) is missing.")
                
                return nil
            }
            
            item.root = superItem
            
            // TODO: persist and maintain item order
            superItem.add(item)
        }
        
        // return root
        
        if root == nil
        {
            log(error: "Record array contains no root.")
        }
        
        return root
    }
}

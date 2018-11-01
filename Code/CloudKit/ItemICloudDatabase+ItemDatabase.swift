import CloudKit
import SwiftObserver
import SwiftyToolz

extension ItemICloudDatabase: ItemDatabase
{
    // MARK: - Fetch & Connect Items
    
    func fetchItemTree(receiveRoot: @escaping (ItemDataTree?) -> Void)
    {
        fetchItemRecords()
        {
            records in
            
            receiveRoot(self.itemTree(from: records))
        }
    }
    
    private func itemTree(from records: [CKRecord]?) -> ItemDataTree?
    {
        // get record array
        
        guard let records = records else
        {
            log(warning: "Record array is nil.")
            
            return nil
        }
        
        // create unconnected items. remember associated records.
        
        var hashMap = [String : (CKRecord, ItemDataTree)]()
        
        for record in records
        {
            guard let modification = record.modification else { continue }
            
            let id = modification.id
            
            hashMap[id] = (record, ItemDataTree(from: modification))
        }
        
        // connect items. find root.
        
        var root: ItemDataTree?
        
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
    
    // MARK: - Save Item Tree
    
    func save(itemTree root: ItemDataTree)
    {
        let itemRecords = records(fromItemTree: root)
        
        save(itemRecords)
    }
    
    private func records(fromItemTree root: ItemDataTree) -> [CKRecord]
    {
        var result = [CKRecord(from: root)]
        
        for subitem in root.branches
        {
            result.append(contentsOf: records(fromItemTree: subitem))
        }
        
        return result
    }
}

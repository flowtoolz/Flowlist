import CloudKit
import SwiftObserver
import SwiftyToolz

extension ItemICloudDatabase: ItemDatabase
{
    // MARK: - Fetch & Connect Items
    
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    {
        fetchItemRecords()
        {
            records in receiveRoot(self.makeItem(from: records))
        }
    }
    
    private func makeItem(from records: [CKRecord]?) -> Item?
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
            guard let modification = record.modification else { continue }
            
            let id = modification.id
            
            hashMap[id] = (record, Item(from: modification))
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
    
    // MARK: - Create
    
    func create(itemTree root: Item)
    {
        let modifications = root.array.map { $0.modification }
        
        createItems(with: modifications)
    }

    
    func createItems(with modifications: [Item.Modification])
    {
        let records = modifications.map { CKRecord(from: $0) }
        
        save(records)
    }
    
    // MARK: - Modify
    
    func modifyItem(with modification: Item.Modification)
    {
        fetchRecord(with: CKRecord.ID(recordName: modification.id))
        {
            guard let record = $0 else { return }
            
            record.apply(modification)
            
            self.save(record) { _ in }
        }
    }
    
    // MARK: - Delete
    
    func deleteItem(with id: String)
    {
        didDeleteRecord(with: CKRecord.ID(recordName: id))
    }
    
    func deleteItems(with ids: [String])
    {
        let recordIDs = ids.map { CKRecord.ID(recordName: $0) }
        
        deleteRecords(withIDs: recordIDs)
    }
}

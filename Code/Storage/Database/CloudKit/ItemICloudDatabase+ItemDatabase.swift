import CloudKit
import SwiftObserver

extension ItemICloudDatabase: ItemDatabase
{
    // MARK: - Apply Edits
    
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .insertItems(let modifications, let rootID):
            insertItems(with: modifications, inRootWithID: rootID)
            
        case .modifyItem(let modification, let rootID):
            modifyItem(with: modification, inRootWithID: rootID)
            
        case .removeItems(let ids):
            removeItems(with: ids)
        }
    }
    
    // MARK: - Manage the Root
    
    func resetItemTree(with root: Item)
    {
        removeItems
        {
            guard $0 else { return }
            
            let records: [CKRecord] = root.array.map
            {
                CKRecord(modification: $0.modification(),
                         superItem: $0.root?.data.id)
            }
            
            self.save(records)
            {
                guard $0 else
                {
                    // TODO: handle failure
                    return
                }
            }
        }
    }
    
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    {
        fetchItemRecords()
        {
            records in receiveRoot(Item(records: records))
        }
    }
}


extension Tree where Data == ItemData
{
    convenience init?(records: [CKRecord]?)
    {
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
            
            hashMap[id] = (record, Item(modification: modification))
        }
        
        // connect items. find root.
        
        var root: Item?
        
        for (record, item) in hashMap.values
        {
            guard let superItemId = record.superItem else
            {
                print("found root: \(record.recordID.recordName) \(record.text)")
                
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

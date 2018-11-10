import CloudKit
import SwiftObserver
import SwiftyToolz

extension ItemICloudDatabase: ItemDatabase
{
    // MARK: - Apply Edits
    
    func apply(_ edit: Edit)
    {
        // TODO: except for modifications that don't involve the position: fetch all siblings and update at least the position of each
        switch edit
        {
        case .insertItems(let modifications, let rootID):
            createItems(with: modifications, inRootWithID: rootID)
        case .modifyItem(let modification, let rootID):
            modifyItem(with: modification, rootID: rootID)
        case .removeItemsWithIds(let ids):
            deleteItems(with: ids)
        }
    }
    
    // MARK: - Create
    
    func createItems(with modifications: [Modification],
                     inRootWithID rootID: String)
    {
        let superitemID = CKRecord.ID(recordName: rootID)
        
        fetchSubitemRecords(withSuperItemID: superitemID)
        {
            // get sorted array of sibling records
            
            guard var siblingRecords = $0 else { return }
            
            siblingRecords.sort
            {
                $0.position ?? 0 < $1.position ?? 0
            }
            
            // insert new records into sibling array
            
            let sortedMods = modifications.sorted
            {
                $0.position ?? 0 < $1.position ?? 0
            }
            
            var recordsToSave = [CKRecord]()
            
            for mod in sortedMods
            {
                guard let pos = mod.position,
                    pos <= siblingRecords.count
                else
                {
                    log(error: "No valid position specified for new item.")
                    return
                }
                
                let newRecord = CKRecord(modification: mod)
                
                siblingRecords.insert(newRecord, at: pos)
                recordsToSave.append(newRecord)
            }
            
            // siblings whose position has shifted must be saved back
            
            for position in 0 ..< siblingRecords.count
            {
                guard siblingRecords[position].position != position else
                {
                    continue
                }
                
                siblingRecords[position].position = position
                recordsToSave.append(siblingRecords[position])
            }
            
            // save records
            
            self.save(recordsToSave)
            {
                success in
                
                // TODO: handle failure
            }
        }
    }
    
    // MARK: - Modify
    
    func modifyItem(with modification: Modification, rootID: String?)
    {
        // TODO: maintain order when item changes position...
        fetchRecord(with: CKRecord.ID(recordName: modification.id))
        {
            guard let record = $0, record.apply(modification) else
            {
                return
            }

            self.save(record) { _ in }
        }
    }
    
    // MARK: - Fetch Item Records
    
    func fetchItemRecords(handleResult: @escaping ([CKRecord]?) -> Void)
    {
        fetchItemRecords(.all, handleResult: handleResult)
    }
    
    func fetchSubitemRecords(of itemRecord: CKRecord,
                             handleResult: @escaping ([CKRecord]?) -> Void)
    {
        guard itemRecord.isItem else { return }
        
        fetchSubitemRecords(withSuperItemID: itemRecord.recordID,
                            handleResult: handleResult)
    }
    
    func fetchSubitemRecords(withSuperItemID id: CKRecord.ID,
                             handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let predicate = NSPredicate(format: "superItem = %@", id)
        
        fetchItemRecords(predicate, handleResult: handleResult)
    }
    
    func fetchItemRecords(_ predicate: NSPredicate,
                          handleResult: @escaping ([CKRecord]?) -> Void)
    {
        let query = CKQuery(recordType: CKRecord.itemType,
                            predicate: predicate)
        
        fetchRecords(with: query, handleResult: handleResult)
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
        {
            success in
            
            // TODO: handle failure
        }
    }
    
    func deleteItems(handleSuccess: @escaping (Bool) -> Void)
    {
        deleteRecords(ofType: CKRecord.itemType,
                      handleSuccess: handleSuccess)
    }
    
    // MARK: - Manage the Root
    
    func resetItemTree(with modifications: [Modification])
    {
        deleteItems
        {
            guard $0 else { return }
            
            let records = modifications.map { CKRecord(modification: $0) }
            
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
                log(error: "Record for super item with id \(superItemId) is missing.")
                
                return nil
            }
            
            item.root = superItem
            
            superItem.add(item)
        }
        
        if root == nil
        {
            log(error: "Record array contains no root.")
        }
        
        // sort and return root
        
        root?.sortWithoutSendingUpdate
        {
            let leftPosition = hashMap[$0.data.id]?.0.position ?? 0
            let rightPosition = hashMap[$1.data.id]?.0.position ?? 0
            
            return leftPosition < rightPosition
        }
        
        return root
    }
}

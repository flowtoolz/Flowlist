import CloudKit
import SwiftObserver
import SwiftyToolz

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
    
    // MARK: - Insert
    
    func insertItems(with modifications: [Modification],
                     inRootWithID rootID: String?)
    {
        guard let rootID = rootID else
        {
            log(warning: "Attempting to create new root item in iCloud DB. This cannot currently happen through regular user interaction.")
            
            let records = modifications.map { CKRecord(modification: $0) }
            
            self.save(records)
            {
                guard $0 else
                {
                    log(error: "Couldn't save records.")
                    return
                }
            }
            
            return
        }
        
        let superitemID = CKRecord.ID(recordName: rootID)
        
        fetchSubitemRecords(withSuperItemID: superitemID)
        {
            // get sorted array of sibling records
            
            guard var siblingRecords = $0 else
            {
                log(error: "Couldn't get sibling records.")
                return
            }
            
            guard !siblingRecords.isEmpty else
            {
                let recordsToSave = modifications.map
                {
                    CKRecord(modification: $0)
                }
                
                self.save(recordsToSave)
                {
                    guard $0 else
                    {
                        log(error: "Couldn't save records.")
                        return
                    }
                }
                
                return
            }
            
            siblingRecords.sort { $0.position < $1.position }
            
            // insert new records into sibling array
            
            let sortedMods = modifications.sorted { $0.position < $1.position }
            
            var recordsToSave = [CKRecord]()
            
            for modification in sortedMods
            {
                let targetPosition = modification.position
                
                guard targetPosition <= siblingRecords.count else
                {
                    log(error: "Invalid position specified for new item.")
                    return
                }
                
                let newRecord = CKRecord(modification: modification)
                
                siblingRecords.insert(newRecord, at: targetPosition)
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
                guard $0 else
                {
                    log(error: "Couldn't save records.")
                    
                    // TODO: handle failure
                    
                    return
                }
            }
        }
    }
    
    // MARK: - Modify
    
    func modifyItem(with modification: Modification,
                    inRootWithID rootID: String?)
    {
        let recordID = CKRecord.ID(recordName: modification.id)
        
        guard let rootID = rootID else
        {
            log(warning: "Attempting to modify root item. This cannot happen through regular user interaction.")
            
            fetchRecord(with: recordID)
            {
                guard let record = $0 else
                {
                    log(error: "Didn't find root item record to modify.")
                    return
                }
                
                if let superItem = record.superItem
                {
                    log(warning: "Record of supposed root item (no root ID was provided) has itself a super item: \(superItem)")
                }

                guard record.apply(modification) else { return }
                
                self.save(record)
                {
                    guard let savedRecord = $0 else
                    {
                        log(error: "Couldn't save record.")
                        // TODO: handle failure
                        return
                    }
                }
            }
            
            return
        }
        
        fetchRecord(with: recordID)
        {
            guard let record = $0 else
            {
                log(error: "Didn't find item record to modify.")
                return
            }
            
            if record.superItem == nil
            {
                log(warning: "Record of supposed subitem (a root ID was provided) has itself no superitem.")
            }
            
            let oldPosition = record.position

            guard record.apply(modification) else
            {
                log(warning: "Modification didn't change iCloud record. This is unexpected.")
                return
            }
            
            let mustUpdatePositions = modification.modifiesPosition || record.position != oldPosition
            
            guard mustUpdatePositions else
            {
                self.save(record)
                {
                    guard let savedRecord = $0 else
                    {
                        log(error: "Couldn't save record.")
                        // TODO: handle failure
                        return
                    }
                }
                
                return
            }
            
            // TODO: more specifically fetch only those records whose position is >= the smallest position among the new "modifications" ... for efficiency: pass insert position with edit event
            
            let superitemID = CKRecord.ID(recordName: rootID)
            
            self.fetchSubitemRecords(withSuperItemID: superitemID)
            {
                // get sorted array of sibling records (includes moved record)
                
                guard var siblingRecords = $0 else { return }
                
                siblingRecords.sort { $0.position < $1.position }
                
                // replace modified record
                
                siblingRecords.remove
                {
                    $0.recordID.recordName == record.recordID.recordName
                }
                
                siblingRecords.insert(record, at: modification.position)
                
                // siblings whose position has shifted must be saved back
                
                var recordsToSave = [record]
                
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
                    guard $0 else
                    {
                        log(error: "Couldn't save records.")
                        
                        // TODO: handle failure
                        
                        return
                    }
                }
            }
        }
    }
    
    // MARK: - Remove
    
    func removeItems(with ids: [String])
    {
        let recordIDs = ids.map { CKRecord.ID(recordName: $0) }
        
        deleteRecords(withIDs: recordIDs)
        {
            success in
            
            // TODO: handle failure
        }
    }
    
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    {
        deleteRecords(ofType: CKRecord.itemType,
                      handleSuccess: handleSuccess)
    }
    
    // MARK: - Fetch
    
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
    
    // MARK: - Manage the Root
    
    func resetItemTree(with modifications: [Modification])
    {
        removeItems
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

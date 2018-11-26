import CloudKit
import SwiftObserver

extension ItemICloudDatabase
{
    // MARK: - Modify
    
    func modifyItem(with modification: Modification,
                    handleSuccess: @escaping (Bool) -> Void)
    {
        let recordID = CKRecord.ID(itemID: modification.id)
        
        guard let rootID = modification.rootID else
        {
            log(warning: "Attempting to modify root item. This cannot happen through regular user interaction.")
            
            fetchRecord(with: recordID)
            {
                guard let record = $0 else
                {
                    log(error: "Didn't find root item record to modify.")
                    handleSuccess(false)
                    return
                }
                
                if let superItem = record.superItem
                {
                    log(warning: "Record of supposed root item (no root ID was provided) has itself a super item: \(superItem)")
                }

                guard record.apply(modification) else
                {
                    log(warning: "Modification didn't change iCloud root record. This is unexpected.")
                    handleSuccess(true)
                    return
                }
                
                self.save([record])
                {
                    guard $0 else
                    {
                        log(error: "Couldn't save record.")
                        handleSuccess(false)
                        return
                    }
                    
                    handleSuccess(true)
                }
            }
            
            return
        }
        
        fetchRecord(with: recordID)
        {
            guard let record = $0 else
            {
                log(error: "Didn't find item record to modify.")
                handleSuccess(false)
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
                handleSuccess(true)
                return
            }
            
            let mustUpdatePositions = modification.modifiesPosition || record.position != oldPosition
            
            guard mustUpdatePositions else
            {
                self.save([record])
                {
                    guard $0 else
                    {
                        log(error: "Couldn't save record.")
                        handleSuccess(false)
                        return
                    }
                    
                    handleSuccess(true)
                }
                
                return
            }
            
            // TODO: more specifically fetch only those records whose position is >= the smallest position among the new "modifications" ... for efficiency: pass insert position with edit event
            
            let superitemID = CKRecord.ID(itemID: rootID)
            
            self.fetchSubitemRecords(withSuperItemID: superitemID)
            {
                // get sorted array of sibling records (includes moved record)
                
                guard var siblingRecords = $0 else
                {
                    log(error: "Couldn't download sibling records.")
                    handleSuccess(false)
                    return
                }
                
                siblingRecords.sort { $0.position < $1.position }
                
                // replace modified record
                
                siblingRecords.remove
                {
                    $0.recordID.recordName == record.recordID.recordName
                }
                
                // FIXME: crashes with index out of range when moving item around
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
                        handleSuccess(false)
                        return
                    }
                    
                    handleSuccess(true)
                }
            }
        }
    }
}
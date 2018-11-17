import CloudKit
import SwiftObserver

extension ItemICloudDatabase
{
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
                log(error: "Couldn't download sibling records.")
                return
            }
            
            guard !siblingRecords.isEmpty else
            {
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
            
            siblingRecords.sort { $0.position < $1.position }
            
            // insert new sibling records into sibling array
            
            var recordsToSave = [CKRecord]()
            
            let sortedNewModifications = modifications.sorted
            {
                $0.position < $1.position
            }
            
            var foundAtLeastOneNewSibling = false
            
            for newModification in sortedNewModifications
            {
                let newRecord = CKRecord(modification: newModification)
                recordsToSave.append(newRecord)
                
                guard newModification.rootID == rootID else { continue }
                
                foundAtLeastOneNewSibling = true
                
                let targetPosition = newModification.position
                
                if targetPosition > siblingRecords.count
                {
                    log(error: "Invalid position specified for new item.")
                    return
                }
                
                let insertPosition = min(targetPosition, siblingRecords.count)
                siblingRecords.insert(newRecord, at: insertPosition)
            }
            
            if !foundAtLeastOneNewSibling
            {
                log(error: "None of the items that are supposed to be inserted into item \(rootID) actually have that item as their root. The items are still being saved to iCloud, but their tree structure is corrupted.")
            }
            else
            {
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
            }
            
            // save records
            
            self.save(recordsToSave)
            {
                guard $0 else
                {
                    log(error: "Couldn't save records.")
                    return
                }
            }
        }
    }
}

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
            
            let records = modifications.map
            {
                CKRecord(modification: $0, superItem: nil)
            }
            
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
                let recordsToSave = modifications.map
                {
                    CKRecord(modification: $0, superItem: rootID)
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
                
                let newRecord = CKRecord(modification: modification,
                                         superItem: rootID)
                
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
                    return
                }
            }
        }
    }
}

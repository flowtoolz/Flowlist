import CloudKit
import SwiftObserver

extension ItemICloudDatabase
{
    // MARK: - Update
    
    func updateItems(with mods: [Modification],
                     inRootWithID rootID: String,
                     handleSuccess: @escaping (Bool) -> Void)
    {
        let superitemID = CKRecord.ID(itemID: rootID)
        
        fetchSubitemRecords(withSuperItemID: superitemID)
        {
            // get sibling records
            
            guard var siblingRecords = $0 else
            {
                log(error: "Couldn't fetch sibling records.")
                handleSuccess(false)
                return
            }
            
            guard !siblingRecords.isEmpty else
            {
                let records = mods.map { CKRecord(modification: $0) }
                
                self.save(records)
                {
                    guard $0 else
                    {
                        log(error: "Couldn't save records.")
                        handleSuccess(false)
                        return
                    }
                    
                    handleSuccess(true)
                }
                
                return
            }
         
            // create hashmap of sibling records
            
            var siblingRecordsByID = [String : CKRecord]()
            
            for record in siblingRecords
            {
                siblingRecordsByID[record.recordID.recordName] = record
            }
            
            // add new records & update existing ones
            
            var recordsToSave = Set<CKRecord>()
            
            for mod in mods
            {
                if let existingRecord = siblingRecordsByID[mod.id]
                {
                    if existingRecord.apply(mod)
                    {
                        recordsToSave.insert(existingRecord)
                    }
                }
                else
                {
                    let newRecord = CKRecord(modification: mod)
                    
                    siblingRecords.append(newRecord)
                    recordsToSave.insert(newRecord)
                }
            }
            
            // update positions
            
            siblingRecords.sort { $0.position < $1.position }
            
            for position in 0 ..< siblingRecords.count
            {
                if siblingRecords[position].position != position
                {
                    siblingRecords[position].position = position
                    recordsToSave.insert(siblingRecords[position])
                }
            }
            
            // save records back
            
            self.save(Array(recordsToSave))
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

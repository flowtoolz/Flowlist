import CloudKit
import SwiftObserver
import SwiftyToolz

extension ItemData
{
    convenience init?(from ckRecord: CKRecord)
    {
        guard ckRecord.recordType == "Item" else
        {
            log(error: "iCloud record type is \"\(ckRecord.recordType)\". Expected\"Item\".")
            
            return nil
        }
        
        self.init(id: ckRecord.recordID.recordName)
        
        text <- ckRecord["text"]
        state <- State(from: ckRecord["state"])
        tag <- Tag(from: ckRecord["tag"])
    }
}

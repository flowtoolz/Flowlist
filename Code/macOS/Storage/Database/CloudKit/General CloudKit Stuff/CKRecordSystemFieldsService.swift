import CloudKit
import SwiftyToolz

class CKRecordSystemFieldsService
{
    func encodeWithSystemFields(_ ckRecord: CKRecord) -> Data
    {
        let ckRecordData = NSMutableData()
        let ckRecordEncoder = NSKeyedArchiver(forWritingWith: ckRecordData)
        ckRecordEncoder.requiresSecureCoding = true
        ckRecord.encodeSystemFields(with: ckRecordEncoder)
        ckRecordEncoder.finishEncoding()
        return ckRecordData as Data
    }
    
    func decodeCKRecord(fromSystemFieldEncoding ckRecordData: Data) -> CKRecord?
    {
        let ckRecordDecoder = NSKeyedUnarchiver(forReadingWith: ckRecordData)
        ckRecordDecoder.requiresSecureCoding = true
        let record = CKRecord(coder: ckRecordDecoder)
        ckRecordDecoder.finishDecoding()
        return record
    }
}

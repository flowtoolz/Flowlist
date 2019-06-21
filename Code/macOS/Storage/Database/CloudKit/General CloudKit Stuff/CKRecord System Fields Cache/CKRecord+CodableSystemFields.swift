import CloudKit

extension CKRecord
{
    convenience init?(fromSystemFieldEncoding data: Data)
    {
        let decoder = NSKeyedUnarchiver(forReadingWith: data)
        decoder.requiresSecureCoding = true
        self.init(coder: decoder)
        decoder.finishDecoding()
    }
    
    var systemFieldEncoding: Data
    {
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)
        encoder.requiresSecureCoding = true
        encodeSystemFields(with: encoder)
        encoder.finishEncoding()
        return data as Data
    }
}

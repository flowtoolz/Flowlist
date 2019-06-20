import CloudKit
import Foundation
import FoundationToolz
import SwiftyToolz

class CKRecordSystemFieldsCache
{
    @discardableResult
    func save(_ ckRecord: CKRecord) -> URL?
    {
        guard let directory = cacheDirectory else { return nil }
        let recordUUID = ckRecord.recordID.recordName
        let fileURL = directory.appendingPathComponent(recordUUID)
        return encodeWithSystemFields(ckRecord).save(to: fileURL)
    }
    
    private func encodeWithSystemFields(_ ckRecord: CKRecord) -> Data
    {
        let ckRecordData = NSMutableData()
        let ckRecordEncoder = NSKeyedArchiver(forWritingWith: ckRecordData)
        ckRecordEncoder.requiresSecureCoding = true
        ckRecord.encodeSystemFields(with: ckRecordEncoder)
        ckRecordEncoder.finishEncoding()
        return ckRecordData as Data
    }
    
    private func decodeCKRecord(fromSystemFieldEncoding ckRecordData: Data) -> CKRecord?
    {
        let ckRecordDecoder = NSKeyedUnarchiver(forReadingWith: ckRecordData)
        ckRecordDecoder.requiresSecureCoding = true
        let record = CKRecord(coder: ckRecordDecoder)
        ckRecordDecoder.finishDecoding()
        return record
    }
    
    private var cacheDirectory: URL?
    {
        guard let docDirectory = URL.documentDirectory else { return nil }
        let cacheDirName = "iCloud Cache"
        let cacheDirURL = docDirectory.appendingPathComponent(cacheDirName)

        let fileManager = FileManager.default
        
        let cacheDirectoryExists = fileManager.fileExists(atPath: cacheDirURL.path,
                                                          isDirectory: nil)
        
        if !cacheDirectoryExists
        {
            do
            {
                try fileManager.createDirectory(at: cacheDirURL,
                                                withIntermediateDirectories: true)
            }
            catch
            {
                log(error: error.localizedDescription)
                return nil
            }
        }
        
        return cacheDirURL
    }
}

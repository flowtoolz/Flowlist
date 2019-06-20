import CloudKit
import Foundation
import FoundationToolz
import SwiftyToolz

class CKRecordSystemFieldsCache
{
    // MARK: - Loading CloudKit Records
    
    func loadCKRecord(with id: String) -> CKRecord?
    {
        guard let directory = cacheDirectory else { return nil }
        let file = directory.appendingPathComponent(id)
        do
        {
            let data = try Data(contentsOf: file)
            return decodeCKRecord(fromSystemFieldEncoding: data)
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    private func decodeCKRecord(fromSystemFieldEncoding ckRecordData: Data) -> CKRecord?
    {
        let decoder = NSKeyedUnarchiver(forReadingWith: ckRecordData)
        decoder.requiresSecureCoding = true
        let ckRecord = CKRecord(coder: decoder)
        decoder.finishDecoding()
        return ckRecord
    }
    
    // MARK: - Saving CloudKit Records
    
    @discardableResult
    func save(_ ckRecord: CKRecord) -> URL?
    {
        guard let directory = cacheDirectory else { return nil }
        let recordUUID = ckRecord.recordID.recordName
        let file = directory.appendingPathComponent(recordUUID)
        return encodeWithSystemFields(ckRecord).save(to: file)
    }
    
    private func encodeWithSystemFields(_ ckRecord: CKRecord) -> Data
    {
        let data = NSMutableData()
        let encoder = NSKeyedArchiver(forWritingWith: data)
        encoder.requiresSecureCoding = true
        ckRecord.encodeSystemFields(with: encoder)
        encoder.finishEncoding()
        return data as Data
    }
    
    // MARK: - The CloudKit Record Cache Directory
    
    private var cacheDirectory: URL?
    {
        guard let docDirectory = URL.documentDirectory else { return nil }
        let cacheDirName = "iCloud Cache"
        let cacheDir = docDirectory.appendingPathComponent(cacheDirName)

        let fileManager = FileManager.default
        
        let cacheDirectoryExists = fileManager.fileExists(atPath: cacheDir.path,
                                                          isDirectory: nil)
        
        if !cacheDirectoryExists
        {
            do
            {
                try fileManager.createDirectory(at: cacheDir,
                                                withIntermediateDirectories: true)
            }
            catch
            {
                log(error: error.localizedDescription)
                return nil
            }
        }
        
        return cacheDir
    }
}

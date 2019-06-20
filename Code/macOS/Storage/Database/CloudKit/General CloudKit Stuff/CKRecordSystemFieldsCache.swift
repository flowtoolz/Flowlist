import CloudKit
import Foundation
import FoundationToolz
import SwiftyToolz

// TODO: Possibly improve performance: Load all CKRecords to memory at launch and store them back typically when we save the JSON file ... or/and: do file saving on background thread

class CKRecordSystemFieldsCache
{
    // MARK: - Get CKRecord That Has Correct System Fields
    
    func getCKRecord(with id: String) -> CKRecord
    {
        if let existingCKRecord = loadCKRecord(with: id)
        {
            return existingCKRecord
        }
        
        let newRecordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let newCKRecord = CKRecord(recordType: recordType, recordID: newRecordID)
        
        save(newCKRecord)
        
        return newCKRecord
    }
    
    // MARK: - Loading CloudKit Records
    
    private func loadCKRecord(with id: String) -> CKRecord?
    {
        guard let directory = directory else { return nil }
        let file = directory.appendingPathComponent(id)
        guard FileManager.default.fileExists(atPath: file.path) else { return nil }
        
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
        guard let directory = directory else { return nil }
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
    
    // MARK: - Delete All Files
    
    @discardableResult
    func clean() -> Bool
    {
        guard let directory = directory else { return false }
        
        do
        {
            try FileManager.default.removeItem(at: directory)
            return true
        }
        catch
        {
            log(error: error.localizedDescription)
            return false
        }
    }
    
    // MARK: - The CloudKit Record Cache Directory
    
    private(set) lazy var directory: URL? =
    {
        guard let docDirectory = URL.documentDirectory else { return nil }
        let cacheDir = docDirectory
            .appendingPathComponent(name)
            .appendingPathComponent(zoneID.zoneName)
            .appendingPathComponent(recordType)
        let fileManager = FileManager.default
        let cacheDirectoryExists = fileManager.fileExists(atPath: cacheDir.path)
        
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
    }()
    
    // MARK: - Configuration
    
    init(name: String,
         zoneID: CKRecordZone.ID,
         recordType: CKRecord.RecordType)
    {
        self.name = name
        self.zoneID = zoneID
        self.recordType = recordType
    }
    
    private let name: String
    private let zoneID: CKRecordZone.ID
    private let recordType: CKRecord.RecordType
}

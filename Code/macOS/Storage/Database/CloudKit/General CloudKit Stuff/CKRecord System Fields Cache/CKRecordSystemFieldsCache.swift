import CloudKit
import Foundation
import FoundationToolz
import SwiftyToolz

// TODO: Possibly improve performance: Load all CKRecords to memory at launch and store them back typically when we save the JSON file ... or/and: do file saving on background thread

class CKRecordSystemFieldsCache
{
    // MARK: - Get CKRecord That Has Correct System Fields
    
    func getCKRecord(with id: String,
                     type: CKRecord.RecordType,
                     zoneID: CKRecordZone.ID) -> CKRecord
    {
        if let existingCKRecord = loadCKRecord(with: id)
        {
            return existingCKRecord
        }
        
        let newCKRecordID = CKRecord.ID(recordName: id, zoneID: zoneID)
        let newCKRecord = CKRecord(recordType: type, recordID: newCKRecordID)
        
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
            return CKRecord(fromSystemFieldEncoding: data)
        }
        catch
        {
            log(error: error.localizedDescription)
            return nil
        }
    }
    
    // MARK: - Saving CloudKit Records
    
    @discardableResult
    func save(_ ckRecords: [CKRecord]) -> [URL?]?
    {
        guard let directory = directory else { return nil }
        
        return ckRecords.map
        {
            ckRecord in
            
            let recordUUID = ckRecord.recordID.recordName
            let file = directory.appendingPathComponent(recordUUID)
            return ckRecord.systemFieldEncoding.save(to: file)
        }
    }
    
    @discardableResult
    func save(_ ckRecord: CKRecord) -> URL?
    {
        guard let directory = directory else { return nil }
        let recordUUID = ckRecord.recordID.recordName
        let file = directory.appendingPathComponent(recordUUID)
        return ckRecord.systemFieldEncoding.save(to: file)
    }
    
    // MARK: - Deleting CloudKit Records
    
    // TODO: write unit test for deletion funcs
    @discardableResult
    func deleteCKRecords(with ids: [CKRecord.ID]) -> Bool
    {
        guard let directory = directory else { return false }
        
        var allGood = true
        
        for id in ids
        {
            let file = directory.appendingPathComponent(id.recordName)
            
            do
            {
                try FileManager.default.removeItem(at: file)
            }
            catch
            {
                log(error: error.readable.message)
                allGood = false
            }
        }
        
        return allGood
    }
    
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
        let cacheDir = docDirectory.appendingPathComponent(name)
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
                log(error: error.readable.message)
                return nil
            }
        }
        
        return cacheDir
    }()
    
    // MARK: - Configuration
    
    init(name: String)
    {
        self.name = name
    }
    
    private let name: String
}



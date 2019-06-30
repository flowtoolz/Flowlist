import Foundation
import FoundationToolz
import SwiftyToolz

class FileSystemDatabase: LocalDatabase
{
    // MARK: - Load & Save
    
    func loadRecords() -> [Record]
    {
        guard let recordFileDirectory = recordFileDirectory else { return [] }
        
        let recordFiles = FileManager.default.items(in: recordFileDirectory)
        
        if !recordFiles.isEmpty { return recordFiles.compactMap(Record.init) }
        
        // no records -> migrate json file?
        
        let jsonMigrator = JSONFileMigrator()
        
        guard jsonMigrator.jsonFileExists,
            let jsonFileRecords = jsonMigrator.loadRecordsFromJSONFile(),
            !jsonFileRecords.isEmpty,
            save(jsonFileRecords)
        else
        {
            return save([newRootRecord]) ? [newRootRecord] : []
        }
        
        // successful migration -> delete json and reload records
        
        jsonMigrator.removeJSONFile()

        return FileManager.default.items(in: recordFileDirectory).compactMap(Record.init)
    }
    
    @discardableResult
    func save(_ records: [Record]) -> Bool
    {
        guard let recordFileDirectory = recordFileDirectory else { return false }
        
        var saveFailed = false
        
        for record in records
        {
            let file = recordFileDirectory.appendingPathComponent(record.id)
            
            if record.save(to: file) == nil { saveFailed = true }
        }
        
        return !saveFailed
    }
    
    // MARK: - Basics
    
    let recordFileDirectory: URL? =
    {
        let directoryName = "Flowlist Item Record Files"
        
        guard let directory = URL.documentDirectory?.appendingPathComponent(directoryName) else
        {
            log(error: "Couldn't get URL of document directory")
            return nil
        }
        
        return FileManager.default.ensureDirectoryExists(directory)
    }()
    
    private var newRootRecord: Record
    {
        return Record(id: .makeUUID(), text: NSFullUserName(), rootID: nil, position: 0)
    }
}

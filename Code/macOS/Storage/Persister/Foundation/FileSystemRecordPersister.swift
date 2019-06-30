import Foundation
import FoundationToolz
import SwiftyToolz

class FileSystemRecordPersister: RecordPersister
{
    // MARK: - Load & Save
    
    func loadRecords() -> [Record]
    {
        // TODO: migrate data from JSON ...DeprecatedJSONFile().loadRecords(initialRoot: newRootRecord)
        
        return FileManager.default.files(in: recordFileDirectory).compactMap(Record.init)
    }
    
    func save(_ records: [Record])
    {
        guard let recordFileDirectory = recordFileDirectory else { return }
        
        for record in records
        {
            record.save(to: recordFileDirectory.appendingPathComponent(record.id))
        }
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
        
        FileManager.default.ensureDirectoryExists(directory)
        
        return directory
    }()
    
    private var newRootRecord: Record
    {
        return Record(id: .makeUUID(), text: NSFullUserName(), rootID: nil, position: 0)
    }
}

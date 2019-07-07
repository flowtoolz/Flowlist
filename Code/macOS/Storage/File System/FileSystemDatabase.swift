import Foundation
import FoundationToolz
import SwiftObserver
import SwiftyToolz

class FileSystemDatabase: CustomObservable
{
    static let shared = FileSystemDatabase()
    private init() {}
    
    // MARK: - Load
    
    
    // how do we initially "load"? not at all (only when demanding records?) should migration be extracted as a setup step? 
    func loadRecords() -> [Record]
    {
        guard let recordFileDirectory = recordFileDirectory else { return [] }
        
        let recordFiles = FileManager.default.items(in: recordFileDirectory)
        
        if !recordFiles.isEmpty { return recordFiles.compactMap(Record.init) }
        
        // no records -> migrate json file?
        
        let jsonMigrator = JSONFileMigrator()
        
        guard jsonMigrator.jsonFileExists,
            let jsonFileRecords = jsonMigrator.loadRecordsFromJSONFile(),
            !jsonFileRecords.isEmpty
        else
        {
            save([newRootRecord])
            return [newRootRecord]
        }
        
        // we have records from a json file -> save records, delete json, reload records
        
        save(jsonFileRecords)
        
        jsonMigrator.removeJSONFile()

        return FileManager.default.items(in: recordFileDirectory).compactMap(Record.init)
    }
    
    // MARK: - Edit
    
    func save(_ records: [Record])
    {
        guard let recordFileDirectory = recordFileDirectory else { return }
        
        let savedRecords = records.compactMap
        {
            record -> Record? in
            
            let file = recordFileDirectory.appendingPathComponent(record.id)
            return record.save(to: file) != nil ? record : nil
        }
        
        send(.didSaveRecords(savedRecords))
    }
    
    func deleteRecords(with ids: [Record.ID])
    {
        guard let recordFileDirectory = recordFileDirectory else { return }
        
        let idsOfDeletions = ids.compactMap
        {
            id -> String? in
            
            let file = recordFileDirectory.appendingPathComponent(id)
            return FileManager.default.remove(file) ? id : nil
        }
        
        send(.didDeleteRecordsWithIDs(idsOfDeletions))
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
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    
    enum Event
    {
        case didSaveRecords([Record])
        case didDeleteRecordsWithIDs([Record.ID])
    }
}

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
    
    // MARK: - Edit
    
    func save(_ records: [Record]) -> Bool
    {
        guard let recordFileDirectory = recordFileDirectory else { return false }
        
        let savedRecords = records.compactMap
        {
            record -> Record? in
            
            let file = recordFileDirectory.appendingPathComponent(record.id)
            return record.save(to: file) != nil ? record : nil
        }
        
        send(.didModifyRecords(savedRecords))
        
        return records.count == savedRecords.count
    }
    
    func deleteRecords(with ids: [Record.ID]) -> Bool
    {
        guard let recordFileDirectory = recordFileDirectory else { return false }
        
        let idsOfDeletions = ids.compactMap
        {
            id -> String? in
            
            let file = recordFileDirectory.appendingPathComponent(id)
            return FileManager.default.remove(file) ? id : nil
        }
        
        send(.didDeleteRecordsWithIDs(idsOfDeletions))
        
        return ids.count == idsOfDeletions.count
    }
    
//    func clear() -> Bool
//    {
//        let files = FileManager.default.items(in: recordFileDirectory)
//
//        var errorOccured = false
//
//        let idsOfRemovedRecords = files.compactMap
//        {
//            file -> String? in
//
//            guard let record = Record(fileURL: file) else
//            {
//                errorOccured = true
//                return nil
//            }
//
//            if FileManager.default.remove(file)
//            {
//                return record.id
//            }
//            else
//            {
//                errorOccured = true
//                return nil
//            }
//        }
//
//        send(.didDeleteRecordsWithIDs(idsOfRemovedRecords))
//
//        return !errorOccured
//    }
    
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
        case didModifyRecords([Record])
        case didDeleteRecordsWithIDs([Record.ID])
    }
}

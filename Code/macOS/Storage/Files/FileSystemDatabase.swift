import Foundation
import FoundationToolz
import PromiseKit
import SwiftObserver
import SwiftyToolz

class FileSystemDatabase: CustomObservable
{
    static let shared = FileSystemDatabase()
    private init() {}
    
    // MARK: - Load
    
    func loadRecords() -> [Record]
    {
        return FileManager.default
            .items(in: recordFileDirectory)
            .compactMap(Record.init)
    }
    
    // MARK: - Edit
    
    @discardableResult
    func save(_ records: [Record],
              identifyAs object: AnyObject,
              sendEvent: Bool = true) -> Bool
    {
        guard !records.isEmpty else { return true }
        
        guard let recordFileDirectory = recordFileDirectory else { return false }
        
        let savedRecords = records.compactMap
        {
            record -> Record? in
            
            let file = recordFileDirectory.appendingPathComponent(record.id)
            return record.save(to: file) != nil ? record : nil
        }
        
        if !savedRecords.isEmpty && sendEvent
        {
            send((object, did: .saveRecords(savedRecords)))
        }
        
        return records.count == savedRecords.count
    }
    
    func deleteRecords(with ids: [Record.ID], identifyAs object: AnyObject)
    {
        guard let recordFileDirectory = recordFileDirectory else { return }
        
        let idsOfDeletions = ids.compactMap
        {
            id -> String? in
            
            let file = recordFileDirectory.appendingPathComponent(id)
            return FileManager.default.remove(file) ? id : nil
        }
        
        if !idsOfDeletions.isEmpty
        {
            send((object, did: .deleteRecordsWithIDs(idsOfDeletions)))
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
        
        return FileManager.default.ensureDirectoryExists(directory)
    }()
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    
    typealias Event = (object: AnyObject, did: Edit)
    
    enum Edit
    {
        case saveRecords([Record])
        case deleteRecordsWithIDs([Record.ID])
    }
}

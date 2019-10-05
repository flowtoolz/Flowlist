import Foundation
import FoundationToolz
import PromiseKit
import SwiftObserver
import SwiftyToolz

class FileDatabase: CustomObservable
{
    // MARK: - Initialization
    
    static let shared = FileDatabase()
    private init() {}
    
    // MARK: - Load
    
    func record(for id: Record.ID) -> Record?
    {
        Record(from: file(for: id))
    }
    
    func loadRecords() -> [Record]
    {
        loadFiles().compactMap(Record.init)
    }
    
    func loadFiles() -> [URL]
    {
        fileManager.items(in: directory)
    }
    
    // MARK: - Edit
    
    @discardableResult
    func save(_ records: [Record],
              identifyAs object: AnyObject,
              sendEvent: Bool = true) -> Bool
    {
        guard !records.isEmpty else { return true }
        
        let savedRecords = records.compactMap
        {
            $0.save(to: file(for: $0.id)) != nil ? $0 : nil
        }
        
        if !savedRecords.isEmpty && sendEvent
        {
            send((object, did: .saveRecords(savedRecords)))
        }
        
        return records.count == savedRecords.count
    }
    
    func deleteRecords(with ids: [Record.ID], identifyAs object: AnyObject)
    {
        guard !ids.isEmpty else { return }
        
        let idsOfDeletions = ids.compactMap
        {
            fileManager.remove(file(for: $0)) ? $0 : nil
        }
        
        if !idsOfDeletions.isEmpty
        {
            send((object, did: .deleteRecordsWithIDs(idsOfDeletions)))
        }
    }
    
    // MARK: - Basics
    
    func file(for id: Record.ID) -> URL
    {
        directory.appendingPathComponent(id + ".json")
    }
    
    let directory: URL =
    {
        let dir = URL.flowlistDirectory.appendingPathComponent("Items")
        FileManager.default.ensureDirectoryExists(dir)
        return dir
    }()
    
    private var fileManager: FileManager { .default }
    
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

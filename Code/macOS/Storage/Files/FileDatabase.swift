import Foundation
import FoundationToolz
import PromiseKit
import SwiftObserver
import SwiftyToolz

class FileDatabase: Observable
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
    func save(_ records: [Record], as author: AnyAuthor, sendEvent: Bool = true) -> Bool
    {
        guard !records.isEmpty else { return true }
        
        let savedRecords = records.compactMap
        {
            $0.save(to: file(for: $0.id)) != nil ? $0 : nil
        }
        
        if !savedRecords.isEmpty && sendEvent
        {
            send(.didSaveRecords(savedRecords), from: author)
        }
        
        return records.count == savedRecords.count
    }
    
    func deleteRecords(with ids: [Record.ID], as author: AnyAuthor)
    {
        guard !ids.isEmpty else { return }
        
        let idsOfDeletions = ids.compactMap
        {
            fileManager.remove(file(for: $0)) ? $0 : nil
        }
        
        if !idsOfDeletions.isEmpty
        {
            send(.didDeleteRecordsWithIDs(idsOfDeletions), from: author)
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
    
    let messenger = Messenger<Event>()

    enum Event
    {
        case didSaveRecords([Record])
        case didDeleteRecordsWithIDs([Record.ID])
    }
}

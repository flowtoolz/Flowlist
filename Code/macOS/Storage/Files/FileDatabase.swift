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
        return Record(fileURL: directory?.file(for: id))
    }
    
    var count: Int { return files.count }
    
    func loadRecords() -> [Record]
    {
        return files.compactMap(Record.init)
    }
    
    private var files: [URL] { return fileManager.items(in: directory) }
    
    // MARK: - Edit
    
    @discardableResult
    func save(_ records: [Record],
              identifyAs object: AnyObject,
              sendEvent: Bool = true) -> Bool
    {
        guard !records.isEmpty else { return true }
        guard let directory = directory else { return false }
        
        let savedRecords = records.compactMap
        {
            $0.save(to: directory.file(for: $0.id)) != nil ? $0 : nil
        }
        
        if !savedRecords.isEmpty && sendEvent
        {
            send((object, did: .saveRecords(savedRecords)))
        }
        
        return records.count == savedRecords.count
    }
    
    func deleteRecords(with ids: [Record.ID], identifyAs object: AnyObject)
    {
        guard let directory = directory else { return }
        
        let idsOfDeletions = ids.compactMap
        {
            fileManager.remove(directory.file(for: $0)) ? $0 : nil
        }
        
        if !idsOfDeletions.isEmpty
        {
            send((object, did: .deleteRecordsWithIDs(idsOfDeletions)))
        }
    }
    
    // MARK: - Basics
    
    private(set) lazy var directory: URL? =
    {
        let name = "Flowlist Item Record Files"
        
        guard let directory = URL.documentDirectory?.appendingPathComponent(name) else
        {
            log(error: "Couldn't get URL of document directory")
            return nil
        }
        
        return fileManager.ensureDirectoryExists(directory)
    }()
    
    private var fileManager: FileManager { return .default }
    
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

private extension URL
{
    func file(for id: Record.ID) -> URL
    {
        return appendingPathComponent(id)
    }
}

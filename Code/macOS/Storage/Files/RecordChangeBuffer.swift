import FoundationToolz
import SwiftyToolz

class RecordChangeBuffer
{
    // MARK: - Initialization
    
    static let shared = RecordChangeBuffer()
    private init() { load() }
    
    // MARK: - Manage Changes
    
    var hasChanges: Bool { !edits.isEmpty || !deletions.isEmpty }
    
    func save(_ records: [Record])
    {
        records.forEach
        {
            deletions.remove($0.id)
            edits.insert($0.id)
        }
        
        save()
    }
    
    func deleteRecords(with ids: [Record.ID])
    {
        ids.forEach
        {
            edits.remove($0)
            deletions.insert($0)
        }
        
        save()
    }
    
    func clear()
    {
        edits.removeAll()
        FileManager.default.remove(editsFile)
        
        deletions.removeAll()
        FileManager.default.remove(deletionsFile)
    }
    
    // MARK: - Persist Changes
    
    private func load()
    {
        edits = RecordIDs(from: editsFile) ?? []
        deletions = RecordIDs(from: deletionsFile) ?? []
    }
    
    private func save()
    {
        deletions.save(to: deletionsFile)
        edits.save(to: editsFile)
    }
    
    private let deletionsFile = RecordChangeBuffer.directory.appendingPathComponent("deletions.json")
    private let editsFile = RecordChangeBuffer.directory.appendingPathComponent("edits.json")
    
    private static var directory: URL
    {
        let dir = URL.flowlistDirectory.appendingPathComponent("Offline Changes")
        FileManager.default.ensureDirectoryExists(dir)
        return dir
    }
    
    // MARK: - Changes
    
    private(set) var edits = RecordIDs()
    private(set) var deletions = RecordIDs()
    
    typealias RecordIDs = Set<Record.ID>
}

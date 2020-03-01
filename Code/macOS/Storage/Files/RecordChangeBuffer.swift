import FoundationToolz
import SwiftyToolz

class RecordChangeBuffer
{
    // MARK: - Initialization
    
    static let shared = RecordChangeBuffer()
    private init() { loadFromFiles() }
    
    // MARK: - Manage Changes
    
    func save(_ records: [Record])
    {
        records.forEach
        {
            deletions.remove($0.id)
            edits.insert($0.id)
        }
        
        saveToFiles()
    }
    
    func deleteRecords(with ids: [Record.ID])
    {
        ids.forEach
        {
            edits.remove($0)
            deletions.insert($0)
        }
        
        saveToFiles()
    }
    
    func clear()
    {
        edits.removeAll()
        FileManager.default.remove(editsFile)
        
        deletions.removeAll()
        FileManager.default.remove(deletionsFile)
    }
    
    // MARK: - Persist Changes in Files
    
    private func loadFromFiles()
    {
        edits = RecordIDs(from: editsFile) ?? []
        deletions = RecordIDs(from: deletionsFile) ?? []
    }
    
    private func saveToFiles()
    {
        deletions.save(to: deletionsFile)
        edits.save(to: editsFile)
    }
    
    private let deletionsFile = directory.appendingPathComponent("deletions.json")
    private let editsFile = directory.appendingPathComponent("edits.json")
    
    private static var directory: URL
    {
        let dir = URL.flowlistDirectory.appendingPathComponent("Record Change Buffer")
        FileManager.default.ensureDirectoryExists(dir)
        return dir
    }
    
    // MARK: - In Mempory Changes
    
    var hasChangesInMemory: Bool { !edits.isEmpty || !deletions.isEmpty }
    
    private(set) var edits = RecordIDs()
    private(set) var deletions = RecordIDs()
    
    typealias RecordIDs = Set<Record.ID>
}

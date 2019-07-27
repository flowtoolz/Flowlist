import FoundationToolz
import SwiftyToolz

class OfflineChanges
{
    // MARK: - Initialization
    
    static let shared = OfflineChanges()
    private init() { load() }
    
    // MARK: - Manage Changes
    
    var hasChanges: Bool { return !edits.isEmpty || !deletions.isEmpty }
    
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
        if FileManager.default.itemExists(editsFile)
        {
            edits = RecordIDs(from: editsFile) ?? []
        }
        
        if FileManager.default.itemExists(deletionsFile)
        {
            deletions = RecordIDs(from: deletionsFile) ?? []
        }
    }
    
    private func save()
    {
        deletions.save(to: deletionsFile)
        edits.save(to: editsFile)
    }
    
    private let deletionsFile = OfflineChanges.directory.appendingPathComponent("deletions.json")
    private let editsFile = OfflineChanges.directory.appendingPathComponent("edits.json")
    
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
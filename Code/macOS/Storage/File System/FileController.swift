import SwiftObserver

class FileController: Observer
{
    // MARK: - Life Cycle
    
    init() { observeRecordStorages() }
    deinit { stopObserving() }
    
    // MARK: - Setup: Load Records from Files
    
    func saveRecordsFromFilesToRecordStore()
    {
        RecordStore.shared.save(FileSystemDatabase.shared.loadRecords(),
                                identifyAs: self)
    }
    
    // MARK: - Observe Record Storages
    
    private func observeRecordStorages()
    {
        observe(FileSystemDatabase.shared)
        {
            [weak self] in if let event = $0 { self?.fileSystemDatabaseDidSend(event) }
        }
        
        observe(RecordStore.shared)
        {
            [weak self] in if let event = $0 { self?.recordStoreDidSend(event) }
        }
    }
    
    private func recordStoreDidSend(_ event: RecordStore.Event)
    {
        switch event
        {
        case .objectDidMofifyRecords(let object, let records):
            guard object !== self else { break }
            FileSystemDatabase.shared.save(records, identifyAs: self)
            
        case .objectDidDeleteRecordsWithIDs(let object, let ids):
            guard object !== self else { break }
            FileSystemDatabase.shared.deleteRecords(with: ids, identifyAs: self)
        }
    }
    
    private func fileSystemDatabaseDidSend(_ event: FileSystemDatabase.Event)
    {
        switch event
        {
        case .objectDidSaveRecords(let object, let records):
            guard object !== self else { break }
            RecordStore.shared.save(records, identifyAs: self)
            
        case .objectDidDeleteRecordsWithIDs(let object, let ids):
            guard object !== self else { break }
            RecordStore.shared.deleteRecords(with: ids, identifyAs: self)
        }
    }
}

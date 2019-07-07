import SwiftObserver

class FileController: Observer
{
    // MARK: - Life Cycle
    
    init() { observeRecordStorages() }
    
    deinit { stopObserving() }
    
    // MARK: - Setup: Load Records from Files
    
    func loadRecords()
    {
        RecordStore.shared.save(FileSystemDatabase.shared.loadRecords())
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
        case .didDeleteRecordsWithIDs(let ids):
            FileSystemDatabase.shared.deleteRecords(with: ids)
        
        case .didMofifyRecords(let records):
            FileSystemDatabase.shared.save(records)
        }
    }
    
    private func fileSystemDatabaseDidSend(_ event: FileSystemDatabase.Event)
    {
        switch event
        {
        case .didSaveRecords(let records):
            RecordStore.shared.save(records)
            
        case .didDeleteRecordsWithIDs(let ids):
            RecordStore.shared.deleteRecords(with: ids)
        }
    }
}

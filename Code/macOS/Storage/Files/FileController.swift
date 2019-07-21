import SwiftObserver

class FileController: Observer
{
    // MARK: - Life Cycle
    
    init()
    {
        observeFileSystemDatabase()
        observeRecordStore()
    }
    
    deinit { stopObserving() }
    
    // MARK: - Setup: Load Records from Files
    
    func saveRecordsFromFilesToRecordStore()
    {
        RecordStore.shared.save(FileSystemDatabase.shared.loadRecords(), identifyAs: self)
    }
    
    // MARK: - Observe Record Store
    
    private func observeRecordStore()
    {
        observe(RecordStore.shared).filter
        {
            [weak self] event in event != nil && event?.object !== self
        }
        .map
        {
            event in event?.did
        }
        .unwrap(.modifyRecords([]))
        {
            [weak self] edit in self?.recordStore(did: edit)
        }
    }
    
    private func recordStore(did edit: RecordStore.Edit)
    {
        switch edit
        {
        case .modifyRecords(let records):
            FileSystemDatabase.shared.save(records, identifyAs: self)
            
        case .deleteRecordsWithIDs(let ids):
            FileSystemDatabase.shared.deleteRecords(with: ids, identifyAs: self)
        }
    }
    
    // MARK: - Observe File System Database
    
    private func observeFileSystemDatabase()
    {
        observe(FileSystemDatabase.shared).filter
        {
            [weak self] event in event != nil && event?.object !== self
        }
        .map
        {
            event in event?.did
        }
        .unwrap(.saveRecords([]))
        {
            [weak self] edit in self?.fileSystemDatabase(did: edit)
        }
    }
    
    private func fileSystemDatabase(did edit: FileSystemDatabase.Edit)
    {
        switch edit
        {
        case .saveRecords(let records):
            RecordStore.shared.save(records, identifyAs: self)
            
        case .deleteRecordsWithIDs(let ids):
            RecordStore.shared.deleteRecords(with: ids, identifyAs: self)
        }
    }
}

import SwiftObserver

class FileController: Observer
{
    // MARK: - Life Cycle
    
    init()
    {
        observeFileDatabase()
        observeRecordStore()
    }
    
    deinit { stopObserving() }
    
    // MARK: - Setup: Load Records from Files
    
    func saveRecordsFromFilesToRecordStore()
    {
        RecordStore.shared.save(FileDatabase.shared.loadRecords(), identifyAs: self)
    }
    
    // MARK: - Observe Record Store
    
    private func observeRecordStore()
    {
        observe(RecordStore.shared).unwrap().filter
        {
            [weak self] event in self != nil && event.object !== self
        }
        .receive
        {
            [weak self] event in self?.recordStore(did: event.did)
        }
    }
    
    private func recordStore(did edit: RecordStore.Edit)
    {
        switch edit
        {
        case .modifyRecords(let records):
            FileDatabase.shared.save(records, identifyAs: self)
            
        case .deleteRecordsWithIDs(let ids):
            FileDatabase.shared.deleteRecords(with: ids, identifyAs: self)
        }
    }
    
    // MARK: - Observe File System Database
    
    private func observeFileDatabase()
    {
        observe(FileDatabase.shared).unwrap().filter
        {
            [weak self] event in self != nil && event.object !== self
        }
        .receive
        {
            [weak self] event in self?.fileSystemDatabase(did: event.did)
        }
    }
    
    private func fileSystemDatabase(did edit: FileDatabase.Edit)
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

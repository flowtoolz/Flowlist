import SwiftObserver

class FileController: Observer
{
    // MARK: - Life Cycle
    
    init()
    {
        observeFileDatabase()
        observeRecordStore()
    }
    
    // MARK: - Setup: Load Records from Files
    
    func saveRecordsFromFilesToRecordStore()
    {
        RecordStore.shared.save(FileDatabase.shared.loadRecords(), as: self)
    }
    
    // MARK: - Observe Record Store
    
    private func observeRecordStore()
    {
        observe(RecordStore.shared)
        {
            [weak self] event, author in
            
            guard let self = self, author !== self else { return }
            
            self.recordStoreDidSend(event)
        }
    }
    
    private func recordStoreDidSend(_ event: RecordStore.Event)
    {
        switch event
        {
        case .didModifyRecords(let records):
            FileDatabase.shared.save(records, as: self)
            
        case .didDeleteRecordsWithIDs(let ids):
            FileDatabase.shared.deleteRecords(with: ids, as: self)
        }
    }
    
    // MARK: - Observe File System Database
    
    private func observeFileDatabase()
    {
        observe(FileDatabase.shared)
        {
            [weak self] event, author in
            
            guard let self = self, author !== self else { return }
        
            self.fileSystemDatabaseDidSend(event)
        }
    }
    
    private func fileSystemDatabaseDidSend(_ event: FileDatabase.Event)
    {
        switch event
        {
        case .didSaveRecords(let records):
            RecordStore.shared.save(records, as: self)
            
        case .didDeleteRecordsWithIDs(let ids):
            RecordStore.shared.deleteRecords(with: ids, as: self)
        }
    }
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

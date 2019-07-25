import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

class CKRecordController: Observer
{
    // MARK: - Life Cycle

    init()
    {
        observeCKRecordDatabase()
        observeFileDatabase()
    }
    
    deinit { stopObserving() }
    
    // MARK: - Transmit CKRecord Database Changes to File Database
    
    private func observeCKRecordDatabase()
    {
        observe(ckRecordDatabase).filter
        {
            [weak self] _ in self?.sync.isActive ?? false
        }
        .select(.mayHaveChanged)
        {
            [weak self] in self?.ckRecordDatabaseMayHaveChanged()
        }
    }
    
    private func ckRecordDatabaseMayHaveChanged()
    {
        guard !offline.hasChanges else
        {
            log(error: "Offline changes haven't been synced properly")
            resync().catch(sync.abort)
            return
        }
        
        fetchCKChangesAndApplyThemToFileDatabase().catch(sync.abort)
    }
    
    // MARK: - Transmit File Database Changes to CKRecord Database
    
    private func observeFileDatabase()
    {
        observe(fileDatabase).filter
        {
            [weak self] in $0 != nil && $0?.object !== self && self?.sync.isActive ?? false
        }
        .map
        {
            event in event?.did
        }
        .unwrap(.saveRecords([]))
        {
            [weak self] edit in self?.fileDatabase(did: edit)
        }
    }
    
    private func fileDatabase(did edit: FileDatabase.Edit)
    {
        guard !offline.hasChanges else
        {
            log(error: "Offline changes haven't been synced properly")
            resync().catch(sync.abort)
            return
        }
        
        switch edit
        {
        case .saveRecords(let records):
            guard isOnline != false else { return offline.save(records) }
            saveToCKRecordDatabase(records).catch(sync.abort)
            
        case .deleteRecordsWithIDs(let ids):
            guard isOnline != false else { return offline.deleteRecords(with: ids) }
            deleteCKRecordsFromCKRecordDatabase(with: ids).catch(sync.abort)
        }
    }
    
    // MARK: - React to Events
    
    func accountDidChange()
    {
        resync().catch(sync.abort)
    }
    
    func userDidToggleSync()
    {
        sync.isActive.toggle()
        
        // when user toggles intention to sync, we ensure that next resync will be total resync so we don't need to persist changes that happen while there is no sync intention
        ckRecordDatabase.deleteChangeToken()

        resync().catch(sync.abort)
    }
    
    func networkReachabilityDidUpdate(isReachable: Bool)
    {
        let reachabilityDidChange = isOnline != nil && isOnline != isReachable
        isOnline = isReachable

        if reachabilityDidChange && isReachable
        {
            resync().catch(sync.abort)
        }
    }
    
    private var isOnline: Bool?
    
    // MARK: - Resync
    
    func resync() -> Promise<Void>
    {
        guard sync.isActive else { return Promise() }
        
        return ckRecordDatabase.hasChangeToken ? resyncWithChangeToken() : resyncWithoutChangeToken()
    }
    
    private func resyncWithoutChangeToken() -> Promise<Void>
    {
        guard !ckRecordDatabase.hasChangeToken else
        {
            return .fail("Tried to sync with iCloud without change token but there is one.")
        }
        
        if offline.hasChanges { offline.clear() }
        
        return firstly
        {
            saveToCKRecordDatabase(fileDatabase.loadRecords())
        }
        .then(on: queue)
        {
            self.ckRecordDatabase.fetchChanges()
        }
        .map(on: queue)
        {
            $0.changedCKRecords.map { $0.makeRecord() }
        }
        .done(on: queue)
        {
            self.fileDatabase.save($0, identifyAs: self)
        }
    }
    
    private func resyncWithChangeToken() -> Promise<Void>
    {
        guard ckRecordDatabase.hasChangeToken else
        {
            return .fail("Tried to sync with iCloud based on change token but there is none.")
        }
        
        return firstly
        {
            applyOfflineChangesToCKRecordDatabase()
        }
        .then(on: queue)
        {
            self.fetchCKChangesAndApplyThemToFileDatabase()
        }
    }
    
    private func fetchCKChangesAndApplyThemToFileDatabase() -> Promise<Void>
    {
        return firstly
        {
            ckRecordDatabase.fetchChanges()
        }
        .done(on: queue)
        {
            self.applyCKChangesToFileDatabase($0)
        }
    }
    
    private func applyCKChangesToFileDatabase(_ changes: CKDatabase.Changes)
    {
        guard changes.hasChanges else { return }
        
        let ids = changes.idsOfDeletedCKRecords.map { $0.recordName }
        fileDatabase.deleteRecords(with: ids, identifyAs: self)
        
        let records = changes.changedCKRecords.map { $0.makeRecord() }
        fileDatabase.save(records, identifyAs: self)
    }
    
    // MARK: - Offline Changes
    
    private func applyOfflineChangesToCKRecordDatabase() -> Promise<Void>
    {
        guard offline.hasChanges else { return Promise() }
        
        return firstly
        {
            deleteCKRecordsFromCKRecordDatabase(with: Array(offline.deletions))
        }
        .then(on: queue)
        {
            () -> Promise<Void> in
            
            let records = Array(self.offline.edits).compactMap(self.fileDatabase.record)
            
            return self.saveToCKRecordDatabase(records)
        }
        .done
        {
            self.offline.clear()
        }
    }
    
    private var offline: OfflineChanges { return .shared }
    
    // MARK: - Save & Delete Records in iCloud
    
    private func saveToCKRecordDatabase(_ records: [Record]) -> Promise<Void>
    {
        return firstly
        {
            ckRecordDatabase.save(records.map(self.makeCKRecord))
        }
        .then
        {
            saveResult -> Promise<Void> in
            
            try self.ensureNoFailures(in: saveResult)
            
            if saveResult.conflicts.isEmpty { return Promise() }
            
            return firstly
            {
                Dialog.default.askWhetherToPreferICloud()
            }
            .then
            {
                preferICloud -> Promise<Void> in
                
                guard !preferICloud else
                {
                    let serverRecords = saveResult.conflicts.map { $0.serverRecord.makeRecord() }
                    self.fileDatabase.save(serverRecords, identifyAs: self)
                    return Promise()
                }
                
                let resolvedServerRecords = saveResult.conflicts.map
                {
                    conflict -> CKRecord in
                    
                    let clientRecord = conflict.clientRecord
                    let serverRecord = conflict.serverRecord
                    
                    serverRecord.text = clientRecord.text
                    serverRecord.state = clientRecord.state
                    serverRecord.tag = clientRecord.tag
                    serverRecord.superItem = clientRecord.superItem
                    serverRecord.position = clientRecord.position
                
                    return serverRecord
                }
                
                return self.saveToCKRecordDatabaseExpectingNoConflicts(resolvedServerRecords)
            }
        }
    }
    
    private func saveToCKRecordDatabaseExpectingNoConflicts(_ records: [CKRecord]) -> Promise<Void>
    {
        return firstly
        {
            ckRecordDatabase.save(records)
        }
        .done
        {
            saveResult -> Void in
            
            try self.ensureNoFailures(in: saveResult)
            
            guard saveResult.conflicts.isEmpty else
            {
                throw ReadableError.message("Couldn't save \(saveResult.conflicts.count) of \(records.count) items to iCloud due to conflicts.")
            }
        }
    }
    
    private func ensureNoFailures(in saveResult: CKDatabase.SaveResult) throws
    {
        if let firstFailure = saveResult.failures.first
        {
            throw ReadableError.message("Couldn't save \(saveResult.failures.count) items to iCloud. First encountered error: \(firstFailure.error.readable.message)")
        }
    }

    private func makeCKRecord(for record: Record) -> CKRecord
    {
        let ckRecord = ckRecordDatabase.getCKRecordWithCachedSystemFields(for: .init(record.id))
        
        ckRecord.text = record.text
        ckRecord.state = record.state
        ckRecord.tag = record.tag
        
        ckRecord.superItem = record.parent
        ckRecord.position = record.position
        
        return ckRecord
    }
    
    private func deleteCKRecordsFromCKRecordDatabase(with ids: [Record.ID]) -> Promise<Void>
    {
        return firstly
        {
            ckRecordDatabase.deleteCKRecords(with: .ckRecordIDs(ids))
        }
        .done
        {
            if let firstFailure = $0.failures.first
            {
                throw ReadableError.message("Couldn't delete \($0.failures.count) of \(ids.count) items from iCloud. First encountered error: \(firstFailure.error.readable.message)")
            }
        }
    }
    
    // MARK: - Intention to Sync With iCloud
    
    func abortSync(with error: Error) { sync.abort(with: error) }
    var isIntendingToSync: Bool { return sync.isActive }
    private let sync = CKSyncIntention()
    
    // MARK: - Databases
    
    private var fileDatabase: FileDatabase { return .shared }
    
    private var queue: DispatchQueue { return ckRecordDatabase.queue }
    private var ckRecordDatabase: CKRecordDatabase { return .shared }
}

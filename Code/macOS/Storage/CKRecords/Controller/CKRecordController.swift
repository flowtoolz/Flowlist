import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

// TODO: note about syncing deletions: deletions cannot cause CloudKit conflicts! when server or client has deleted a record while the other side has changed it, the client would probably win when applying his change or deletion to the server. whether change or deletion survives would depend on which client resyncs last. however if the change should always win (so that no records accidentally get deleted), then do this on resync: first save modified records to server and resolve conflicts reported by CloudKit, then fetch changes from server and apply them locally, THEN check the client's own deletions and ONLY apply those that do NOT correspond to fetched record changes.

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
            saveToCKRecordDatabaseHandlingConflicts(records).catch(sync.abort)
            
        case .deleteRecordsWithIDs(let ids):
            guard isOnline != false else { return offline.deleteRecords(with: ids) }
            // TODO: Handle Deletion Result
            ckRecordDatabase.deleteCKRecords(with: .ckRecordIDs(ids)).catch(sync.abort)
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
            saveToCKRecordDatabaseHandlingConflicts(fileDatabase.loadRecords())
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
    
    private func applyOfflineChangesToCKRecordDatabase() -> Promise<Void>
    {
        guard offline.hasChanges else { return Promise() }
        
        return firstly
        {
            () -> Promise<Void> in
            
            let deletionIDs = Array(offline.deletions)
            // TODO: Handle Deletion Result
            return ckRecordDatabase.deleteCKRecords(with: .ckRecordIDs(deletionIDs)).map { _ in }
        }
        .then(on: queue)
        {
            () -> Promise<Void> in
            
            let records = Array(self.offline.edits).compactMap(self.fileDatabase.record)
            
            return self.saveToCKRecordDatabaseHandlingConflicts(records)
        }
        .done
        {
            self.offline.clear()
        }
    }
    
    // MARK: - Handle Conflicts
    
    private func saveToCKRecordDatabaseHandlingConflicts(_ records: [Record]) -> Promise<Void>
    {
        return firstly
        {
            ckRecordDatabase.save(records.map(self.makeCKRecord))
        }
        .then
        {
            saveResult -> Promise<Void> in
            
            guard saveResult.failures.isEmpty else
            {
                return .fail("Couldn't save \(saveResult.failures.count) of \(records.count) items to iCloud.")
            }
            
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
                
                return self.saveToCKRecordDatabaseIgnoringConflicts(resolvedServerRecords)
            }
        }
    }
    
    private func saveToCKRecordDatabaseIgnoringConflicts(_ records: [CKRecord]) -> Promise<Void>
    {
        return firstly
        {
            ckRecordDatabase.save(records)
        }
        .done
        {
            saveResult -> Void in
            
            guard saveResult.failures.isEmpty else
            {
                throw ReadableError.message("Couldn't save \(saveResult.failures.count) of \(records.count) items to iCloud.")
            }
            
            guard saveResult.conflicts.isEmpty else
            {
                throw ReadableError.message("Couldn't save \(saveResult.conflicts.count) of \(records.count) items to iCloud due to conflicts.")
            }
        }
    }
    
    // MARK: - Basics
    
    private var isOnline: Bool?
    private var offline: OfflineChanges { return .shared }
    private var fileDatabase: FileDatabase { return .shared }
    
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
    
    // MARK: - CloudKit Database & Intention to Sync With It
    
    func abortSync(with error: Error) { sync.abort(with: error) }
    var isIntendingToSync: Bool { return sync.isActive }
    private let sync = CKSyncIntention()
    
    private var queue: DispatchQueue { return ckRecordDatabase.queue }
    private var ckRecordDatabase: CKRecordDatabase { return .shared }
}

import CloudKit
import PromiseKit
import SwiftObserver
import SwiftyToolz

// TODO: note about syncing deletions: deletions cannot cause CloudKit conflicts! when server or client has deleted a record while the other side has changed it, the client would probably win when applying his change or deletion to the server. whether change or deletion survives would depend on which clients resyncs last. however if the change should always win (so that no records accidentally get deleted), then do this on resync: first save modified records to server and resolve conflicts reported by CloudKit, then fetch changes from server and apply them locally, THEN check the client's own deletions and ONLY apply those that do NOT correspond to fetched record changes.

// TODO: when resolving conflict using type SaveConflict, the resolved version should be written to the server record and that record should be written back to the server

class CKRecordController: Observer
{
    // MARK: - Life Cycle

    init()
    {
        observeCloudKitDatabase()
        observeFileDatabase()
    }
    
    deinit { stopObserving() }
    
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
        
        return firstly
        {
            ckRecordDatabase.fetchChanges()
        }
        .map(on: queue)
        {
            $0.changedCKRecords.map { $0.makeRecord() }
        }
        .then(on: queue)
        {
            cloudRecords in

            return firstly
            {
                () -> Promise<Void> in
                
                // TODO: handle conflicts
                let fileRecords = self.fileDatabase.loadRecords()
                return self.ckRecordDatabase.save(fileRecords.map(self.makeCKRecord)).map { _ in }
            }
            .done(on: self.queue)
            {
                // TODO: handle conflicts
                self.fileDatabase.save(cloudRecords, identifyAs: self)
            }
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
            ckRecordDatabase.fetchChanges()
        }
        .then(on: queue)
        {
            ckChanges in
            
            return firstly
            {
                self.applyOfflineChangesToCKDatabase()
            }
            .done(on: self.queue)
            {
                // TODO: handle conflicts
                self.applyCKChangesToFileDatabase(ckChanges)
            }
        }
    }
    
    private func applyOfflineChangesToCKDatabase() -> Promise<Void>
    {
        guard offline.hasChanges else { return Promise() }
        
        return firstly
        {
            () -> Promise<Void> in
            
            let deletionIDs = Array(offline.idsOfDeletedRecords)
            
            // TODO: handle conflicts
            return ckRecordDatabase.deleteCKRecords(with: .ckRecordIDs(deletionIDs)).map { _ in }
        }
        .then(on: queue)
        {
            () -> Promise<Void> in
            
            let ckRecords = Array(self.offline.idsOfSavedRecords)
                .compactMap(self.fileDatabase.record)
                .map(self.makeCKRecord)
            
            // TODO: handle conflicts
            return self.ckRecordDatabase.save(ckRecords).map { _ in }
        }
    }
    
    // MARK: - Transmit CloudKit Database Changes to File Database
    
    private func observeCloudKitDatabase()
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
        // TODO: what if we have offline changes (in case we weren't reliably notified of coming back online)
        
        firstly
        {
            ckRecordDatabase.fetchChanges()
        }
        .done
        {
            self.applyCKChangesToFileDatabase($0)
        }
        .catch
        {
            log(error: $0.readable.message)
        }
    }
    
    private func applyCKChangesToFileDatabase(_ changes: CKDatabase.Changes)
    {
        guard changes.hasChanges else { return }
        
        // TODO: do need to check for conflicts and possibly ask user or only on resync?
        
        let ids = changes.idsOfDeletedCKRecords.map { $0.recordName }
        fileDatabase.deleteRecords(with: ids, identifyAs: self)
        
        let records = changes.changedCKRecords.map { $0.makeRecord() }
        fileDatabase.save(records, identifyAs: self)
    }
    
    // MARK: - Transmit File Database Changes to CloudKit Database
    
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
        switch edit
        {
        case .saveRecords(let records):
            guard isOnline != false else { return offline.save(records) }
            // TODO: handle conflicts, failure and partial failure
            ckRecordDatabase.save(records.map(makeCKRecord)).catch(sync.abort)
            
        case .deleteRecordsWithIDs(let ids):
            guard isOnline != false else { return offline.deleteRecords(with: ids) }
            ckRecordDatabase.deleteCKRecords(with: .ckRecordIDs(ids)).catch(sync.abort)
        }
    }
    
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

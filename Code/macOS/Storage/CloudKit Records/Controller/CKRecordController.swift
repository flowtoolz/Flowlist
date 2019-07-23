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
        ckDatabase.deleteChangeToken()

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
        
        return ckDatabase.hasChangeToken ? resyncWithChangeToken() : resyncWithoutChangeToken()
    }
    
    private func resyncWithoutChangeToken() -> Promise<Void>
    {
        return firstly
        {
            ckDatabase.fetchChanges()
        }
        .map
        {
            $0.changedCKRecords.map { $0.makeRecord() }
        }
        .done
        {
            cloudRecords in
            
            // FIXME: check conflicts with file database, possibly ask user
            // FIXME: also update cloud with local data
            FileDatabase.shared.save(cloudRecords, identifyAs: self)
        }
    }
    
    private func resyncWithChangeToken() -> Promise<Void>
    {
        guard ckDatabase.hasChangeToken else
        {
            return .fail("Tried to sync with database based on change token while database has no change token.")
        }
        
        // TODO: if there are unsynced local changes, apply them first to database and resolve conflicts
        
        return firstly
        {
            ckDatabase.fetchChanges()
        }
        .done(on: queue)
        {
            self.applyToFileDatabase($0)
        }
    }
    
    // MARK: - Transmit CloudKit Database Changes to File Database
    
    private func observeCloudKitDatabase()
    {
        observe(ckDatabase).filter
        {
            [weak self] _ in self?.sync.isActive ?? false
        }
        .select(.mayHaveChanged)
        {
            [weak self] in self?.ckDatabaseMayHaveChanged()
        }
    }
    
    private func ckDatabaseMayHaveChanged()
    {
        // TODO: what if we have offline changes (in case we weren't reliably notified of coming back online)
        
        firstly
        {
            ckDatabase.fetchChanges()
        }
        .done
        {
            self.applyToFileDatabase($0)
        }
        .catch
        {
            log(error: $0.readable.message)
        }
    }
    
    private func applyToFileDatabase(_ ckDatabaseChanges: CKDatabase.Changes)
    {
        // TODO: do need to check for conflicts and possibly ask user or only on resync?
        
        let ids = ckDatabaseChanges.idsOfDeletedCKRecords.map { $0.recordName }
        fileDatabase.deleteRecords(with: ids, identifyAs: self)
        
        let records = ckDatabaseChanges.changedCKRecords.map { $0.makeRecord() }
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
            ckDatabase.save(records.map(makeCKRecord)).catch(sync.abort)
            
        case .deleteRecordsWithIDs(let ids):
            guard isOnline != false else { return offline.deleteRecords(with: ids) }
            ckDatabase.deleteCKRecords(with: .ckRecordIDs(ids)).catch(sync.abort)
        }
    }
    
    private var isOnline: Bool?
    private var offline: OfflineChanges { return .shared }
    private var fileDatabase: FileDatabase { return .shared }
    
    private func makeCKRecord(for record: Record) -> CKRecord
    {
        let ckRecord = ckDatabase.getCKRecordWithCachedSystemFields(for: .init(record.id))
        
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
    
    private var queue: DispatchQueue { return ckDatabase.queue }
    private var ckDatabase: CloudKitDatabase { return .shared }
}

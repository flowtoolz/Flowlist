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
        observe(CKRecordDatabase.shared).filter
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
            editor.saveCKRecords(for: records).catch(sync.abort)
            
        case .deleteRecordsWithIDs(let ids):
            guard isOnline != false else { return offline.deleteRecords(with: ids) }
            editor.deleteCKRecords(with: ids).catch(sync.abort)
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
        CKRecordDatabase.shared.deleteChangeToken()

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
        
        return CKRecordDatabase.shared.hasChangeToken ? resyncWithChangeToken() : resyncWithoutChangeToken()
    }
    
    private func resyncWithoutChangeToken() -> Promise<Void>
    {
        if CKRecordDatabase.shared.hasChangeToken
        {
            log(warning: "Attempted to sync with iCloud without change token but there is one.")
            CKRecordDatabase.shared.deleteChangeToken()
        }
        
        offline.clear() // on total resync, lingering changes (delta cache) are irrelevant
        
        return firstly
        {
            editor.saveCKRecords(for: fileDatabase.loadRecords())
        }
        .then(on: queue)
        {
            CKRecordDatabase.shared.fetchChanges()
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
        guard CKRecordDatabase.shared.hasChangeToken else
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
            CKRecordDatabase.shared.fetchChanges()
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
            editor.deleteCKRecords(with: Array(offline.deletions))
        }
        .then(on: queue)
        {
            () -> Promise<Void> in
            
            let records = Array(self.offline.edits).compactMap(self.fileDatabase.record)
            
            return self.editor.saveCKRecords(for: records)
        }
        .done
        {
            self.offline.clear()
        }
    }
    
    private var offline: OfflineChanges { return .shared }
    
    // MARK: - Intention to Sync With iCloud
    
    func abortSync(with error: Error) { sync.abort(with: error) }
    var isIntendingToSync: Bool { return sync.isActive }
    private let sync = CKSyncIntention()
    
    // MARK: - Editing Databases
    
    private var fileDatabase: FileDatabase { return .shared }
    private var queue: DispatchQueue { return CKRecordDatabase.shared.queue }
    private let editor = CKRecordEditor()
}

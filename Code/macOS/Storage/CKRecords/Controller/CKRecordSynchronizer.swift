import CloudKit
import SwiftyToolz
import PromiseKit

class CKRecordSynchronizer
{
    // MARK: - React to Events
    
    func ckRecordDatabaseMayHaveChanged()
    {
        guard sync.isActive else { return }
        
        guard !offline.hasChanges else
        {
            log(error: "Offline changes haven't been synced properly")
            return resync()
        }
        
        fetchCKChangesAndApplyThemToFileDatabase().catch(sync.abort)
    }
    
    func fileDatabase(did edit: FileDatabase.Edit)
    {
        guard sync.isActive else { return }
        
        guard !offline.hasChanges else
        {
            log(error: "Offline changes haven't been synced properly")
            return resync()
        }
        
        switch edit
        {
        case .saveRecords(let records):
            guard isOnline else { return offline.save(records) }
            editor.saveCKRecords(for: records).catch(sync.abort)
            
        case .deleteRecordsWithIDs(let ids):
            guard isOnline else { return offline.deleteRecords(with: ids) }
            editor.deleteCKRecords(with: ids).catch(sync.abort)
        }
    }
    
    var isOnline = true
    {
        didSet { if !oldValue && isOnline { resync() } }
    }
    
    func toggleSync()
    {
        sync.isActive.toggle()
        
        // when user toggles intention to sync, we ensure that next resync will be total resync so we don't need to persist changes that happen while there is no sync intention
        CKRecordDatabase.shared.deleteChangeToken()
        
        resync()
    }
    
    // MARK: - Resync
    
    func resync()
    {
        resyncAsynchronously().catch(sync.abort)
    }
    
    func resyncAsynchronously() -> Promise<Void>
    {
        guard sync.isActive else { return Promise() }
        
        return CKRecordDatabase.shared.hasChangeToken
            ? resyncWithChangeToken()
            : resyncWithoutChangeToken()
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
    
    // MARK: - Basics
    
    func abortSync(with error: Error) { sync.abort(with: error) }
    var syncIsActive: Bool { return sync.isActive }
    private let sync = CKSyncIntention()
    
    private var queue: DispatchQueue { return CKRecordDatabase.shared.queue }
    private var fileDatabase: FileDatabase { return .shared }
    private let editor = CKRecordEditor()
}

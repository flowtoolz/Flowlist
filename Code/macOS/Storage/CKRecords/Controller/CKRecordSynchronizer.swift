import CloudKit
import Foundation
import SwiftyToolz
import PromiseKit

class CKRecordSynchronizer
{
    // MARK: - Life Cycle
    
    init() { startTimer() }
    
    deinit { timer?.invalidate() }
    
    // MARK: - React to Events
    
    func ckRecordDatabaseMayHaveChanged()
    {
        guard sync.isActive else { return }
        
        fetchCKChangesAndApplyThemToFileDatabase().catch(sync.abort)
    }
    
    func fileDatabaseDidSend(_ event: FileDatabase.Event)
    {
        guard sync.isActive else { return }
        
        switch event
        {
        case .didSaveRecords(let records): return bufferedChanges.save(records)
        case .didDeleteRecordsWithIDs(let ids): return bufferedChanges.deleteRecords(with: ids)
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
        ckRecordDatabase.deleteChangeToken()
        
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
        
        return ckRecordDatabase.hasChangeToken
            ? resyncWithChangeToken()
            : resyncWithoutChangeToken()
    }
    
    /// Total resync from scratch
    private func resyncWithoutChangeToken() -> Promise<Void>
    {
        if ckRecordDatabase.hasChangeToken
        {
            log(warning: "Attempted to sync with iCloud without change token but there is one.")
            ckRecordDatabase.deleteChangeToken()
        }
        
        
        if bufferedChanges.hasChangesInMemory
        {
            // TODO: Can this happen at all? What if there are lots of offline changes buffered that would get lost???
            log(warning: "Attempting a total iCloud resync while there are unsynced local changes that will be lost. Try everything to merge changes before resyncing from scratch.")
        }
        bufferedChanges.clear()
        
        return firstly
        {
            // if we have the latest changetags from the server (system fields cache) then differing fields cause no conflicts but play out as regular edits. here in the beginning, we possibly have no or outdated changetags, so any differing fields might come back as conflicts, which is also fine but super unlikely. in most cases, the local items would, at most, form a separate new tree, causing no conflicts but triggering the tree selection dialog.
            editor.saveCKRecords(for: fileDatabase.loadRecords())
        }
        .then(on: queue)
        {
            // TODO: is this the moment when we could clear the system fields cache? When can we do that to ensure that cache gets emptied once in a while??
            // CKRecordDatabase.shared.clearCachedSystemFields()
            CKRecordDatabase.shared.fetchChanges()
        }
        .map(on: queue)
        {
            $0.changedCKRecords.map { $0.makeRecord() }
        }
        .done(on: queue)
        {
            self.fileDatabase.save($0, as: self)
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
            applyBufferedChangesToCKRecordDatabase()
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
        fileDatabase.deleteRecords(with: ids, as: self)
        
        let records = changes.changedCKRecords.map { $0.makeRecord() }
        fileDatabase.save(records, as: self)
    }
    
    // MARK: - Delayed Sync of Buffered Changes
    
    private func startTimer()
    {
        let syncDelay: TimeInterval = 3.0
        timer = .scheduledTimer(withTimeInterval: syncDelay,
                                repeats: true,
                                block: timerDidFire)
    }
    
    private func timerDidFire(_ timer: Timer)
    {
        guard sync.isActive, !isSyncingBufferedChanges, isOnline else { return }
        applyBufferedChangesToCKRecordDatabase().catch(sync.abort)
    }
    
    private var timer: Timer?
    
    private func applyBufferedChangesToCKRecordDatabase() -> Promise<Void>
    {
        // TODO: return the actual promise that is syncing the changes, and replace the isSyncingBufferedChanges property with that ...
        guard !isSyncingBufferedChanges, bufferedChanges.hasChangesInMemory else { return Promise() }
        
        isSyncingBufferedChanges = true
        
        return firstly
        {
            editor.deleteCKRecords(with: Array(bufferedChanges.deletions))
        }
        .then(on: queue)
        {
            () -> Promise<Void> in
            
            let records = Array(self.bufferedChanges.edits).compactMap(self.fileDatabase.record)
            
            return self.editor.saveCKRecords(for: records)
        }
        .done
        {
            self.bufferedChanges.clear()
            self.isSyncingBufferedChanges = false
        }
    }
    
    private var isSyncingBufferedChanges = false
    private var bufferedChanges: RecordChangeBuffer { .shared }
    
    // MARK: - Basics
    
    private var sync: CKSyncIntention { .shared }
    
    private var fileDatabase: FileDatabase { .shared }
    
    let editor = CKRecordEditor()
    private var queue: DispatchQueue { ckRecordDatabase.queue }
    private var ckRecordDatabase: CKRecordDatabase { .shared }
}

import CloudKit
import Foundation
import SwiftyToolz

class CKRecordSynchronizer
{
    // MARK: - Life Cycle
    
    init() { startTimer() }
    
    deinit { timer?.invalidate() }
    
    // MARK: - React to Events
    
    func ckRecordDatabaseMayHaveChanged()
    {
        guard sync.isActive else { return }
        
        Task
        {
            do
            {
                try await fetchCKChangesAndApplyThemToFileDatabase()
            }
            catch
            {
                sync.abort(with: error)
            }
        }
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
        Task
        {
            do
            {
                try await resyncAsynchronously()
            }
            catch
            {
                sync.abort(with: error)
            }
        }
    }
    
    func resyncAsynchronously() async throws
    {
        guard sync.isActive else { return }
        
        if ckRecordDatabase.hasChangeToken
        {
            try await resyncWithChangeToken()
        }
        else
        {
            try await resyncWithoutChangeToken()
        }
    }
    
    /// Total resync from scratch
    private func resyncWithoutChangeToken() async throws
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
        
        // if we have the latest changetags from the server (system fields cache) then differing fields cause no conflicts but play out as regular edits. here in the beginning, we possibly have no or outdated changetags, so any differing fields might come back as conflicts, which is also fine but super unlikely. in most cases, the local items would, at most, form a separate new tree, causing no conflicts but triggering the tree selection dialog.
        try await editor.saveCKRecords(for: fileDatabase.loadRecords())
        
        // TODO: is this the moment when we could clear the system fields cache? When can we do that to ensure that cache gets emptied once in a while??
        // CKRecordDatabase.shared.clearCachedSystemFields()
        let changes = try await CKRecordDatabase.shared.fetchChanges()
        
        let changedRecords = changes.changedCKRecords.map { $0.makeRecord() }
        fileDatabase.save(changedRecords, as: self)
    }
    
    private func resyncWithChangeToken() async throws
    {
        guard ckRecordDatabase.hasChangeToken else
        {
            throw "Tried to sync with iCloud based on change token but there is none."
        }
        
        try await applyBufferedChangesToCKRecordDatabase()
        try await fetchCKChangesAndApplyThemToFileDatabase()
    }
    
    private func fetchCKChangesAndApplyThemToFileDatabase() async throws
    {
        let changes = try await ckRecordDatabase.fetchChanges()
        applyCKChangesToFileDatabase(changes)
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
        
        Task
        {
            do
            {
                try await applyBufferedChangesToCKRecordDatabase()
            }
            catch
            {
                sync.abort(with: error)
            }
        }
    }
    
    private var timer: Timer?
    
    private func applyBufferedChangesToCKRecordDatabase() async throws
    {
        // TODO: return the actual Task that is syncing the changes, and replace the isSyncingBufferedChanges property with that ...
        guard !isSyncingBufferedChanges, bufferedChanges.hasChangesInMemory else { return }
        
        isSyncingBufferedChanges = true
        try await editor.deleteCKRecords(with: Array(bufferedChanges.deletions))
        let locallyEditedRecords = Array(bufferedChanges.edits).compactMap(fileDatabase.record)
        try await editor.saveCKRecords(for: locallyEditedRecords)
        bufferedChanges.clear()
        isSyncingBufferedChanges = false
    }
    
    private var isSyncingBufferedChanges = false
    private var bufferedChanges: RecordChangeBuffer { .shared }
    
    // MARK: - Basics
    
    private var sync: CKSyncIntention { .shared }
    
    private var fileDatabase: FileDatabase { .shared }
    
    let editor = CKRecordEditor()
    private var ckRecordDatabase: CKRecordDatabase { .shared }
}

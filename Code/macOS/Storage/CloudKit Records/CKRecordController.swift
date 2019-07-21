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
        observeFileSystemDatabase()
    }
    
    deinit { stopObserving() }
    
    // MARK: - Setup: Update Files with Cloud Data
    
    func syncCKRecordsWithFiles() -> Promise<Void>
    {
        guard isIntendingToSync else { return Promise() }

        return Promise
        {
            resolver in
            
            firstly
            {
                resync()
            }
            .done(on: queue)
            {
                resolver.fulfill_()
            }
            .catch
            {
                self.abortIntendingToSync(with: $0)
                resolver.reject($0)
            }
        }
    }
    
    // MARK: - React to Events
    
    func accountDidChange()
    {
        if isIntendingToSync
        {
            resync().catch(abortIntendingToSync)
        }
    }
    
    func toggleIntentionToSync()
    {
        guard !isIntendingToSync else
        {
            syncIntentionPersistentFlag.value = false
            return
        }

        firstly
        {
            resync()
        }
        .done(on: queue)
        {
            self.syncIntentionPersistentFlag.value = true
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Network Reachability
    
    func networkReachabilityDidUpdate(isReachable: Bool)
    {
        let reachabilityDidChange = self.isReachable != nil && self.isReachable != isReachable
        let deviceWentOnline = reachabilityDidChange && isReachable
        
        self.isReachable = isReachable
        
        if deviceWentOnline { syncStoreAndDatabaseAfterDeviceWentOnline() }
    }
    
    private func syncStoreAndDatabaseAfterDeviceWentOnline()
    {
        guard isIntendingToSync else { return }

        firstly
        {
            resync()
        }
        .catch
        {
            let c2a = "Your device just went online but iCloud sync failed. Make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"

            self.abortIntendingToSync(withErrorMessage: $0.readable.message,
                                      callToAction: c2a)
        }
    }
    
    private var isReachable: Bool?
    
    // MARK: - Resync
    
    private func resync() -> Promise<Void>
    {
        if ckDatabase.hasChangeToken
        {
            return resyncWithChangeToken()
        }
        else
        {
            return resyncWithoutChangeToken()
        }
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
            FileSystemDatabase.shared.save(cloudRecords, identifyAs: self)
        }
    }
    
    private func resyncWithChangeToken() -> Promise<Void>
    {
        guard ckDatabase.hasChangeToken else
        {
            return Promise(error: ReadableError.message("Tried to sync with database based on change token while database has no change token."))
        }
        
        // TODO: if there are unsynced local changes, apply them first to database and resolve conflicts
        
        return firstly
        {
            ckDatabase.fetchChanges()
        }
        .done(on: queue)
        {
            self.applyToFileSystemDatabase($0)
        }
    }
    
    private func askUserWhetherToUse(cloudRecords: [Record],
                                     orLocalRecords localRecords: [Record]) -> Promise<Void>
    {
        return firstly
        {
            Dialog.default.askWhetherToPreferICloud()
        }
        .then(on: queue)
        {
            preferDatabase -> Promise<Void> in
            
            if preferDatabase
            {
                FileSystemDatabase.shared.save(cloudRecords, identifyAs: self)
                return Promise()
            }
            else
            {
                return self.ckDatabase.save(localRecords.map(self.makeCKRecord)).map { _ in }
            }
        }
    }
    
    // MARK: - Transmit CloudKit database Changes to File System
    
    private func observeCloudKitDatabase()
    {
        observe(CloudKitDatabase.shared).select(.mayHaveChanged)
        {
            [weak self] in self?.ckDatabaseDidChange()
        }
    }
    
    private func ckDatabaseDidChange()
    {
        firstly
        {
            ckDatabase.fetchChanges()
        }
        .done
        {
            self.applyToFileSystemDatabase($0)
        }
        .catch
        {
            log(error: $0.readable.message)
        }
    }
    
    private func applyToFileSystemDatabase(_ ckDatabaseChanges: CKDatabase.Changes)
    {
        // TODO: check for conflicts, possibly ask user
        
        let ids = ckDatabaseChanges.idsOfDeletedCKRecords.map { $0.recordName }
        FileSystemDatabase.shared.deleteRecords(with: ids, identifyAs: self)
        
        let records = ckDatabaseChanges.changedCKRecords.map { $0.makeRecord() }
        FileSystemDatabase.shared.save(records, identifyAs: self)
    }
    
    // MARK: - Transmit File System Changes to CloudKit Database
    
    private func observeFileSystemDatabase()
    {
        observe(FileSystemDatabase.shared).filter
        {
            [weak self] event in event != nil && event?.object !== self
        }
        .map
        {
            event in event?.did
        }
        .unwrap(.saveRecords([]))
        {
            [weak self] edit in self?.fileSystemDatabase(did: edit)
        }
    }
    
    private func fileSystemDatabase(did edit: FileSystemDatabase.Edit)
    {
        guard isIntendingToSync, isReachable != false else
        {
            hasUnsyncedLocalChanges.value = true
            return
        }

        firstly
        {
            () -> Promise<Void> in
            
            switch edit
            {
            case .saveRecords(let records):
                // TODO: handle conflicts, failure and partial failure
                return ckDatabase.save(records.map(makeCKRecord)).map { _ in }
                
            case .deleteRecordsWithIDs(let ids):
                return ckDatabase.deleteCKRecords(with: ids).map { _ in }
            }
        }
        .catch
        {
            self.hasUnsyncedLocalChanges.value = true
            self.abortIntendingToSync(with: $0)
        }
    }
    
    private func makeCKRecord(for record: Record) -> CKRecord
    {
        let ckRecord = ckDatabase.getCKRecordWithCachedSystemFields(for: record.id)
        
        ckRecord.text = record.text
        ckRecord.state = record.state
        ckRecord.tag = record.tag
        
        ckRecord.superItem = record.rootID
        ckRecord.position = record.position
        
        return ckRecord
    }
    
    private var hasUnsyncedLocalChanges = PersistentFlag("UserDefaultsKeyUnsyncedLocalChanges",
                                                         default: true)
    
    // MARK: - CloudKit Database
    
    private var queue: DispatchQueue { return ckDatabase.queue }
    private var ckDatabase: CloudKitDatabase { return CloudKitDatabase.shared }
    
    // MARK: - Abort Intending to Sync When Errors Occur
    
    private func abortIntendingToSync(with error: Error)
    {
        abortIntendingToSync(withErrorMessage: error.readable.message)
    }
    
    private func abortIntendingToSync(withErrorMessage message: String,
                                      callToAction: String? = nil)
    {
        syncIntentionPersistentFlag.value = false
        
        log(error: message)
        
        let c2a = callToAction ?? "Make sure that 1) Your Mac is online, 2) It is connected to your iCloud account and 3) iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
        
        informUserAboutSyncProblem(error: message, callToAction: c2a)
    }
    
    private func informUserAboutSyncProblem(error: String, callToAction: String)
    {
        let question = Dialog.Question(title: "Whoops, Had to Pause iCloud Sync",
                                       text: "\(error)\n\n\(callToAction)",
            options: ["Got it"])
        
        Dialog.default.pose(question, imageName: "icloud_conflict").catch { _ in }
    }
    
    // MARK: - Persist the User's Intention to Sync
    
    var isIntendingToSync: Bool { return syncIntentionPersistentFlag.value }
    private var syncIntentionPersistentFlag = PersistentFlag("UserDefaultsKeyWantsToUseICloud")
}

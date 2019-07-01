import PromiseKit
import SwiftObserver
import SwiftyToolz

// TODO: note about syncing deletions: deletions cannot cause CloudKit conflicts! when server or client has deleted a record while the other side has changed it, the client would probably win when applying his change or deletion to the server. whether change or deletion survives would depend on which clients resyncs last. however if the change should always win (so that no records accidentally get deleted), then do this on resync: first save modified records to server and resolve conflicts reported by CloudKit, then fetch changes from server and apply them locally, THEN check the client's own deletions and ONLY apply those that do NOT correspond to fetched record changes.

// TODO: when resolving conflict using type SaveConflict, the resolved version should be written to the server record and that record should be written back to the server

class Storage: Observer
{
    // MARK: - Life cycle
    
    init(recordStore: RecordStore)
    {
        self.recordStore = recordStore
        
        observe(recordStore)
        {
            [weak self] in
            
            guard let self = self, let event = $0 else { return }
            
            switch event
            {
            case .cloudDatabaseDidChange:
                self.databaseMayHaveChanged()
                
            case .didDeleteRecordsWithIDs(_):
                break
                
            case .didUpdateRecords(_):
                break
                
            case .didApplyRecordChanges(let changes):
                if !ItemStore.shared.changesAreRedundant(changes)
                {
                    self.applyCloudChangesToItemStore(changes)
                }
            }
            
        }
        
        observe(ItemStore.shared) { [weak self] in self?.didReceive($0) }
    }
    
    deinit { stopObserving() }
    
    // MARK: - App Life Cycle
    
    func appDidLaunch()
    {
        guard let root = recordStore.localDatabase.loadRecords().makeTrees().largestTree else
        {
            log(error: "Couldn't load items from file.")
            return
        }
        
        ItemStore.shared.update(root: root)
        
        if isIntendingToSync
        {
            syncStoreAndDatabase().catch(abortIntendingToSync)
        }
    }
    
    func windowLostFocus() { saveItemsToFile() }
    
    func appWillTerminate() { saveItemsToFile() }
    
    private func saveItemsToFile()
    {
        guard let root = ItemStore.shared.root else
        {
            log(error: "Store root is nil.")
            return
        }
        
        recordStore.localDatabase.save(root.array.map(Record.init))
    }
    
    // MARK: - Database Account Status
    
    func databaseAccountDidChange()
    {
        guard isIntendingToSync else { return }
    
        syncStoreAndDatabase().catch(abortIntendingToSync)
    }
    
    // MARK: - Transmit Database Changes to Local Store
    
    private func databaseMayHaveChanged()
    {
        recordStore.fetchChanges().catch(abortIntendingToSync)
    }
    
    private func applyCloudChangesToItemStore(_ changes: RecordChanges)
    {
        if changes.idsOfDeletedRecords.count > 0
        {
            ItemStore.shared.apply(.removeItems(withIDs: changes.idsOfDeletedRecords))
        }
        
        if changes.modifiedRecords.count > 0
        {
            ItemStore.shared.apply(.updateItems(withRecords: changes.modifiedRecords))
        }
    }
    
    // MARK: - Transmit Local Changes to Database
    
    private func didReceive(_ itemStoreEvent: ItemStore.Event)
    {
        // TODO: should we ignore root switch events here and return?
        
        guard isIntendingToSync, isReachable != false else
        {
            hasUnsyncedLocalChanges.value = true
            return
        }
        
        firstly
        {
            applyItemStoreEventToCloudDatabase(itemStoreEvent)
        }
        .catch
        {
            self.hasUnsyncedLocalChanges.value = true
            self.abortIntendingToSync(with: $0)
        }
    }
    
    // TODO: apply this, but based on CK agnostic SaveConflict type, not store event
    private func handleConflictingStoreEventByAskingUser(_ edit: ItemStore.Event) -> Promise<Void>
    {
        // TODO: Implement, using forced save if necessary. Also implement force option for save.
        /*
        return firstly
        {
            Dialog.default.askWhetherToPreferICloud()
        }
        .then(on: self.dbQueue)
        {
            (preferDatabase: Bool) -> Promise<Void> in
            
            if preferDatabase
            {
                return self.fetchAllDatabaseItemsAndResetLocalStore()
            }
            else
            {
                return self.database.reset(root: Store.shared.root)
            }
        }
        */
        
        return Promise()
    }
    
    private func applyItemStoreEventToCloudDatabase(_ event: ItemStore.Event) -> Promise<Void>
    {
        switch event
        {
        case .didUpdate(let update):
            if let edit = Edit(update)
            {
                // TODO: handle partial failures and conflicts
                switch edit
                {
                case .updateItems(let records):
                    return recordStore.cloudDatabase.save(records).map { _ in }
                case .removeItems(let ids):
                    return recordStore.cloudDatabase.deleteRecords(withIDs: ids).map { _ in }
                }
            }

        case .didSwitchRoot:
            // TODO: should we propagate this to the database, i.e. could it happen anytime?
            log(warning: "Store did switch root. The Storage should respond if this happens not just on app launch.")
            break
            
        case .didNothing: break
        }
        
        return Promise()
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
            syncStoreAndDatabase()
        }
        .catch
        {
            let c2a = "Your device just went online but iCloud sync failed. Make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
            
            self.abortIntendingToSync(withErrorMessage: $0.readable.message, callToAction: c2a)
        }
    }
    
    private var isReachable: Bool?
    
    // MARK: - Let User Toggle Intention to Sync
    
    func toggleIntentionToSyncWithDatabase()
    {
        guard !isIntendingToSync else
        {
            syncIntentionPersistentFlag.value = false
            return
        }
        
        firstly
        {
            syncStoreAndDatabase()
        }
        .done(on: queue)
        {
            self.syncIntentionPersistentFlag.value = true
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Ensure Store and DB Are in Sync
    
    private func syncStoreAndDatabase() -> Promise<Void>
    {
        if recordStore.cloudDatabase.hasChangeToken
        {
            return syncStoreAndDatabaseBasedOnChangeToken()
        }
        else
        {
            return syncStoreAndDatabaseWithoutChangeToken()
        }
    }
    
    private func syncStoreAndDatabaseBasedOnChangeToken() -> Promise<Void>
    {
        guard recordStore.cloudDatabase.hasChangeToken else
        {
            return Promise(error: ReadableError.message("Tried to sync with database based on change token while database has no change token."))
        }
        
        guard ItemStore.shared.root != nil else
        {
            return Promise(error: ReadableError.message("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            recordStore.cloudDatabase.fetchChanges()
        }
        .then(on: queue)
        {
            (dbChanges: RecordChanges) -> Promise<Void> in
            
            if !dbChanges.hasChanges
            {
                // database did not change
                
                if self.hasUnsyncedLocalChanges.value
                {
                    // ... but store did change (like after editing offline)
                    
                    // TODO: we should persist a local cash of changed unsynced records, so we don't have to reset the whole db at this point
                    return self.recordStore.cloudDatabase.reset(withRoot: ItemStore.shared.root)
                }
                else
                {
                    // neither db nor local store have changed. we're done.
                    
                    return Promise()
                }
            }
            else
            {
                // database did change
                
                // TODO: if we had a way to detect that these are our own changes, we coud return Promise() her in that case
                
                if !self.hasUnsyncedLocalChanges.value
                {
                    // ... the local store did not change
                    // like after working on other device or when we changed the db ourselves
                    
                    self.applyCloudChangesToItemStore(dbChanges)
                    
                    return Promise()
                }
                else
                {
                    // db and local items changed
                    
                    // db changes are redundant? -> we're done
                    
                    if ItemStore.shared.changesAreRedundant(dbChanges) { return Promise() }
                    
                    // conflicting db changes -> ask user
                    
                    // TODO: are there simple cases where we can safely say the differences are not in conflict?
                        // a) if there are only insertions of entirely new items, the changes can be merged
                        // b) otherwise we'd need to know at least WHICH items locally changed to avoid overwriting them
                    
                    return firstly
                    {
                        Dialog.default.askWhetherToPreferICloud()
                    }
                    .then(on: self.queue)
                    {
                        (preferDatabase: Bool) -> Promise<Void> in
                        
                        if preferDatabase
                        {
                            return self.fetchAllDatabaseItemsAndResetLocalStore()
                        }
                        else
                        {
                            return self.recordStore.cloudDatabase.reset(withRoot: ItemStore.shared.root)
                        }
                    }
                }
            }
        }
        .done
        {
            self.hasUnsyncedLocalChanges.value = false
        }
    }
    
    private func syncStoreAndDatabaseWithoutChangeToken() -> Promise<Void>
    {
        guard ItemStore.shared.root != nil else
        {
            return Promise(error: ReadableError.message("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            recordStore.cloudDatabase.fetchChanges()
        }
        .map(on: queue)
        {
            self.getTreeRoot(fromFetchedRecords: $0.modifiedRecords)
        }
        .then(on: queue)
        {
            dbRoot -> Promise<Void> in
            
            guard let dbRoot = dbRoot, dbRoot.numberOfLeafs > 1 else
            {
                return self.recordStore.cloudDatabase.reset(withRoot: ItemStore.shared.root)
            }
            
            guard let storeRoot = ItemStore.shared.root, storeRoot.numberOfLeafs > 1 else
            {
                self.resetLocal(tree: dbRoot)
                return Promise()
            }
            
            if storeRoot.isIdentical(to: dbRoot)
            {
                return Promise()
            }
            
            // conflicting trees -> ask user
            
            // TODO: are there simple cases where we can safely say the differences are not in conflict? -> apply db changes locally AND then write local tree (or preferrably only the local changes) to db
            
            return firstly
            {
                Dialog.default.askWhetherToPreferICloud()
            }
            .then(on: self.queue)
            {
                (preferDatabase: Bool) -> Promise<Void> in
                
                if preferDatabase
                {
                    self.resetLocal(tree: dbRoot)
                    return Promise()
                }
                else
                {
                    return self.recordStore.cloudDatabase.reset(withRoot: storeRoot)
                }
            }
        }
        .done
        {
            self.hasUnsyncedLocalChanges.value = false
        }
    }
    
    private func fetchAllDatabaseItemsAndResetLocalStore() -> Promise<Void>
    {
        guard ItemStore.shared.root != nil else
        {
            return Promise(error: ReadableError.message("Create file and Store root before resetting Store with Database items! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            recordStore.cloudDatabase.fetchRecords()
        }
        .map(on: queue)
        {
            self.getTreeRoot(fromFetchedRecords: $0)
        }
        .then(on: queue)
        {
            dbRoot -> Promise<Void> in
            
            guard let storeRoot = ItemStore.shared.root else
            {
                let errorMessage = "Did proceed into \(#function) while local store has no root item."
                log(error: errorMessage)
                throw ReadableError.message(errorMessage)
            }
            
            // no items in database -> reset db with store items
            
            guard let dbRoot = dbRoot else
            {
                return self.recordStore.cloudDatabase.reset(withRoot: storeRoot)
            }
            
            // store and db are identical -> no need to reset store
            
            if ItemStore.shared.root?.isIdentical(to: dbRoot) ?? false
            {
                return Promise()
            }
            
            // reset store with db items
            
            self.resetLocal(tree: dbRoot)
            return Promise()
        }
    }
    
    private func getTreeRoot(fromFetchedRecords records: [Record]) -> Item?
    {
        let treeResult = records.makeTrees()
        
        /* Do we really wanna clear the db just because this client only deals with 1 consistent tree?
        // if database has detached items -> delete them.
        // (detached items have a root that is not in the database.)
        
         if !treeResult.detachedRecords.isEmpty
         {
         let ids = treeResult.detachedRecords.map { $0.id }
         
         self.database.apply(.removeItems(withIDs: ids)).catch
         {
         log(error: $0.readable.message)
         }
         }
         */
        
        // return tree
        
        if treeResult.trees.count > 1
        {
            log(warning: "There are multiple trees in iCloud.")
        
            if let storeRootID = ItemStore.shared.root?.data.id,
                let matchingRoot = treeResult.trees.first(where: { $0.data.id == storeRootID })
            {
                log("... We found a tree in iCloud whos root ID matches the local tree's root ID, so we're gonna use that tree.")
                return matchingRoot
            }
            
            log("... We found no matching root ID in iCloud, so we're gonna use the largest tree from iCloud.")
            return treeResult.largestTree
        }
        else
        {
            return treeResult.trees.first
        }
    }
    
    private var hasUnsyncedLocalChanges = PersistentFlag("UserDefaultsKeyUnsyncedLocalChanges",
                                                         default: true)
    
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
    
    // MARK: - Basics
    
    private func resetLocal(tree: Item)
    {
        ItemStore.shared.update(root: tree)
        recordStore.localDatabase.save(tree.array.map(Record.init))
    }
    
    private var queue: DispatchQueue { return recordStore.queue }
    
    let recordStore: RecordStore
}

extension ItemStore
{
    func changesAreRedundant(_ changes: RecordChanges) -> Bool
    {
        let updatesAreRedundant = differingRecords(in: changes.modifiedRecords).isEmpty
        let deletionsAreRedundant = existingIDs(in: changes.idsOfDeletedRecords).isEmpty
        
        return updatesAreRedundant && deletionsAreRedundant
    }
}

private extension CloudDatabase
{
    func reset(withRoot root: Item?) -> Promise<Void>
    {
        let records = Record.makeRecordsRecursively(for: root)
        return reset(with: records).map { _ in }
    }
}

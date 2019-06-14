import PromiseKit
import SwiftObserver
import SwiftyToolz

class Storage: Observer
{
    // MARK: - Life cycle
    
    init(with file: ItemFile, database: ItemDatabase)
    {
        self.file = file
        self.database = database
        
        observe(database.messenger) { [weak self] in self?.didReceive($0) }
        observe(Store.shared) { [weak self] in self?.didReceive($0) }
    }
    
    deinit { stopObserving() }
    
    // MARK: - App Life Cycle
    
    func appDidLaunch()
    {
        guard let root = file.loadItem() else
        {
            log(error: "Couldn't load items from file.")
            return
        }
        
        Store.shared.update(root: root)
        
        if isIntendingToSync
        {
            firstly
            {
                self.database.ensureAccess()
            }
            .then
            {
                self.syncStoreAndDatabase()
            }
            .catch(abortIntendingToSync)
        }
    }
    
    func windowLostFocus() { saveItemsToFile() }
    
    func appWillTerminate() { saveItemsToFile() }
    
    private func saveItemsToFile()
    {
        guard let root = Store.shared.root else
        {
            log(error: "Store root is nil.")
            return
        }
        
        file.save(root)
    }
    
    // MARK: - Database Account Status
    
    func databaseAccountDidChange()
    {
        guard isIntendingToSync else { return }
        
        if !database.didEnsureAccess && !database.isCheckingAccess
        {
            log(warning: "Syncing with database while db hasn't yet ensured access.")
        }
    
        firstly
        {
            database.ensureAccess()
        }
        .done(on: self.backgroundQ)
        {
            log(warning: "DB account status changed while we were in sync but now we still (or again?) do have access. This is a weird situation. To be totally sure we didn't miss out on db updates, we're gonna resync everything.")
            self.syncStoreAndDatabaseBasedOnChangeToken().catch(self.abortIntendingToSync)
        }
        .catch
        {
            let c2a = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
            
            self.abortIntendingToSync(withErrorMessage: $0.readable.message, callToAction: c2a)
        }
    }
    
    // MARK: - Transmit Database Changes to Local Store
    
    private func didReceive(_ databaseUpdate: ItemDatabaseUpdate)
    {
        switch databaseUpdate
        {
        case .mayHaveChanged: databaseMayHaveChanged()
        }
    }
    
    private func databaseMayHaveChanged()
    {
        firstly
        {
            database.fetchChanges()
        }
        .done(on: backgroundQ)
        {
            self.applyDatabaseChangesToStore($0)
        }
        .catch(abortIntendingToSync)
    }
    
    private func applyDatabaseChangesToStore(_ changes: ItemDatabaseChanges)
    {
        if changes.idsOfDeletedRecords.count > 0
        {
            Store.shared.apply(.removeItems(withIDs: changes.idsOfDeletedRecords))
        }
        
        if changes.modifiedRecords.count > 0
        {
            Store.shared.apply(.updateItems(withRecords: changes.modifiedRecords))
        }
    }
    
    // MARK: - Transmit Local Changes to Database
    
    private func didReceive(_ storeEvent: Store.Event)
    {
        // TODO: should we ignore root switch events here and return?
        
        guard isIntendingToSync, isReachable != false else
        {
            hasUnsyncedLocalChanges.value = true
            return
        }
        
        // TODO: understand and comment: this was for the app launch when welcome tour paste or edit happens before accessibility check is through.... RIGHT??? otherwise, we could remove this whole block ... actually there should be a transaction queue to disentangle editing from db availability ...
        guard database.didEnsureAccess else
        {
            if !database.isCheckingAccess
            {
                let errorMessage = "Tried to edit iCloud database before ensuring access."
                abortIntendingToSync(withErrorMessage: errorMessage)
            }
            
            hasUnsyncedLocalChanges.value = true
            return
        }
        
        applyStoreEventToDatabase(storeEvent)
    }
    
    private func applyStoreEventToDatabase(_ event: Store.Event)
    {
        switch event
        {
        case .didUpdate(let update):
            if let edit = update.makeEdit()
            {
                applyEditToDatabase(edit)
            }

        case .didSwitchRoot:
            // TODO: should we propagate this to the database, i.e. could it happen anytime?
            log(warning: "Store did switch root. The Storage should respond if this happens not just on app launch.")
            break
            
        case .didNothing:
            break
        }
    }
    
    private func applyEditToDatabase(_ edit: Edit)
    {
        // log("applying edit from store to db: \(edit)")

        firstly
        {
            self.database.apply(edit)
        }
        .catch
        {
            self.hasUnsyncedLocalChanges.value = true
            self.abortIntendingToSync(with: $0)
        }
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
            self.database.ensureAccess()
        }
        .done(on: backgroundQ)
        {
            self.syncStoreAndDatabaseBasedOnChangeToken().catch(self.abortIntendingToSync)
        }
        .catch
        {
            let c2a = "Seems like your device just went online but iCloud is unavailable. Make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
            
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
            self.database.ensureAccess()
        }
        .then(on: backgroundQ)
        {
            self.syncStoreAndDatabaseWithoutChangeToken()
        }
        .done(on: backgroundQ)
        {
            self.syncIntentionPersistentFlag.value = true
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Ensure Store and DB Are in Sync
    
    private func syncStoreAndDatabase() -> Promise<Void>
    {
        if database.hasChangeToken
        {
            return self.syncStoreAndDatabaseBasedOnChangeToken()
        }
        else
        {
            return self.syncStoreAndDatabaseWithoutChangeToken()
        }
    }
    
    private func syncStoreAndDatabaseBasedOnChangeToken() -> Promise<Void>
    {
        guard Store.shared.root != nil else
        {
            return Promise(error: ReadableError.message("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            self.database.fetchChanges()
        }
        .then(on: backgroundQ)
        {
            (dbChanges: ItemDatabaseChanges) -> Promise<Void> in
            
            if !dbChanges.hasChanges
            {
                // database did not change
                
                if self.hasUnsyncedLocalChanges.value
                {
                    // ... but store did change (like after editing offline)
                    
                    // TODO: we should persist a local cash of changed unsynced records, so we don't have to reset the whole db at this point
                    return self.database.reset(root: Store.shared.root)
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
                
                if dbChanges.thisAppDidTheChanges { return Promise() }
                
                // some other Flowlist installation did change the database
                
                if !self.hasUnsyncedLocalChanges.value
                {
                    // ... but the local store did not change (like after coming back from other device)
                    
                    self.applyDatabaseChangesToStore(dbChanges)
                    
                    return Promise()
                }
                else
                {
                    // conflicting changes -> ask user
                    
                    return firstly
                    {
                        Dialog.default.askWhetherToPreferICloud()
                    }
                    .then(on: self.backgroundQ)
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
        guard Store.shared.root != nil else
        {
            return Promise(error: ReadableError.message("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            database.fetchChanges()
        }
        .map
        {
            self.getTreeRoot(fromFetchedRecords: $0.modifiedRecords)
        }
        .then
        {
            dbRoot -> Promise<Void> in
            
            guard let dbRoot = dbRoot, dbRoot.numberOfLeafs > 1 else
            {
                return self.database.reset(root: Store.shared.root)
            }
            
            guard let storeRoot = Store.shared.root, storeRoot.numberOfLeafs > 1 else
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
            .then(on: self.backgroundQ)
            {
                (preferDatabase: Bool) -> Promise<Void> in
                
                if preferDatabase
                {
                    self.resetLocal(tree: dbRoot)
                    return Promise()
                }
                else
                {
                    return self.database.reset(root: storeRoot)
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
        guard Store.shared.root != nil else
        {
            return Promise(error: ReadableError.message("Create file and Store root before resetting Store with Database items! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            database.fetchRecords()
        }
        .map(on: backgroundQ)
        {
            self.getTreeRoot(fromFetchedRecords: $0)
        }
        .then(on: backgroundQ)
        {
            dbRoot -> Promise<Void> in
            
            guard let storeRoot = Store.shared.root else
            {
                let errorMessage = "Did proceed into \(#function) while local store has no root item."
                log(error: errorMessage)
                throw ReadableError.message(errorMessage)
            }
            
            // no items in database -> reset db with store items
            
            guard let dbRoot = dbRoot else
            {
                return self.database.reset(root: storeRoot)
            }
            
            // store and db are identical -> no need to reset store
            
            if Store.shared.root?.isIdentical(to: dbRoot) ?? false
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
        
            if let storeRootID = Store.shared.root?.data.id,
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
        Store.shared.update(root: tree)
        file.save(tree)
    }
    
    let database: ItemDatabase
    let file: ItemFile
    
    private var backgroundQ: DispatchQueue
    {
        return DispatchQueue.global(qos: .userInitiated)
    }
}

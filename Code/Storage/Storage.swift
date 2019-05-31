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
        
        observeDatabase()
        observe(Store.shared) { [weak self] in self?.didReceive(storeEvent: $0) }
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
                self.synchronizeStoreAndDatabase()
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
    
    // MARK: - Database Accessibility
    
    func databaseAccessibilityMayHaveChanged()
    {
        guard isIntendingToSync else { return }
        
        if database.isAccessible.value != true
        {
            log(error: "Invalid state: Syncing with database while it's POSSIBLY inaccessible: Is accessible: \(String(describing: database.isAccessible))")
        }
    
        firstly
        {
            database.ensureAccess()
        }
        .done(on: self.backgroundQ)
        {
            if self.hasUnsyncedLocalChanges.value
            {
                self.synchronizeStoreAndDatabase().catch(self.abortIntendingToSync)
            }
        }
        .catch
        {
            let c2a = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
            
            self.abortIntendingToSync(withErrorMessage: $0.message, callToAction: c2a)
        }
    }
    
    // MARK: - Network Reachability
    
    // TODO: Simplify this concern and don't conflate network reachability with "db reachability", what is the latter anyway really. Can't we just use our reachability wrapper for this?
    
    func networkReachabilityDidUpdate(isReachable: Bool)
    {
        guard isIntendingToSync else { return }
        
        guard isReachable else
        {
            // TODO: why??? just because the device went offline doesn't mean we immediately have unsynced changes without changing anything
            hasUnsyncedLocalChanges.value = true
            return
        }
        
        firstly
        {
            self.database.ensureAccess()
        }
        .then
        {
            self.synchronizeStoreAndDatabase()
        }
        .catch
        {
            let c2a = "Seems like this device just went online but iCloud is unavailable. Make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
            
            self.abortIntendingToSync(withErrorMessage: $0.message, callToAction: c2a)
        }
    }
    
    // MARK: - Observe Database & Store

    private func observeDatabase()
    {
        observe(database.messenger)
        {
            guard let edit = $0 else { return }
            
            // log("applying edit from db to store: \(edit)")
            
            Store.shared.apply(edit)
        }
    }
    
    private func didReceive(storeEvent: Store.Event)
    {
        switch storeEvent
        {
        case .didUpdate(let update):
            if let edit = update.makeEdit()
            {
                self.storeWasEdited(edit)
            }
            else
            {
                self.hasUnsyncedLocalChanges.value = true
                
                let errorMessage = "Couldn't interpret Store event `.didUpdate` as editing operation."
                log(error: errorMessage)
                self.abortIntendingToSync(withErrorMessage: errorMessage)
            }
        case .didSwitchRoot:
            // TODO: why do we not propagate this to the database?
            break
        case .didNothing: break
        }
    }
    
    private func storeWasEdited(_ edit: Edit)
    {
        // log("applying edit from store to db: \(edit)")
        
        guard isIntendingToSync else
        {
            hasUnsyncedLocalChanges.value = true
            return
        }
        
        guard database.isAccessible.value == true else
        {
            if !database.isCheckingAccess
            {
                let errorMessage = "Tried to edit iCloud database before ensuring accessibility."
                abortIntendingToSync(withErrorMessage: errorMessage)
            }
            
            hasUnsyncedLocalChanges.value = true
            return
        }
        
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
            self.synchronizeStoreAndDatabase()
        }
        .done(on: backgroundQ)
        {
            self.syncIntentionPersistentFlag.value = true
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Ensure Store and DB Are in Sync
    
    private func synchronizeStoreAndDatabase() -> Promise<Void>
    {
        guard let storeRoot = Store.shared.root else
        {
            return Promise(error: StorageError.message("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            self.database.fetchRecords()
        }
        .then(on: backgroundQ)
        {
            (result: FetchRecordsResult) -> Promise<Void> in
            
            let treeResult = result.records.makeTrees()
            
            if treeResult.trees.count > 1
            {
                log(error: "There are multiple trees in the database.")
            }
            
            guard let databaseRoot = treeResult.trees.first else
            {
                // no items in database
                
                return self.database.reset(tree: storeRoot)
            }
            
            if !storeRoot.isLeaf && databaseRoot.isLeaf
            {
                // no items in database root
                
                return self.database.reset(tree: storeRoot)
            }
            
            // database has items that we can't delete
            
            if !treeResult.detachedRecords.isEmpty
            {
                // remove detached records from db
                
                let ids = treeResult.detachedRecords.map { $0.id }
                
                self.database.apply(.removeItems(withIDs: ids)).catch
                {
                    log(error: $0.storageError.message)
                }
            }
            
            if storeRoot.isLeaf && !databaseRoot.isLeaf
            {
                // no items in Store root but in database
                
                self.resetLocal(tree: databaseRoot)
                return Promise()
            }
            
            // store and database have items
            
            if storeRoot.isIdentical(to: databaseRoot)
            {
                // Store and iCloud are identical
                
                return Promise()
            }
            
            // store and database have different items
            
            if self.hasUnsyncedLocalChanges.value && !result.dbWasModified
            {
                // store changed but not database
                // (like after editing offline)
                
                return self.database.reset(tree: storeRoot)
            }
            
            if !self.hasUnsyncedLocalChanges.value && result.dbWasModified
            {
                // database changed but not store
                // (like after editing from other device)
                
                self.resetLocal(tree: databaseRoot)
                return Promise()
            }
            
            // conflicting trees -> ask user
            
            return firstly
            {
                Dialog.default.askWhetherToPreferICloud()
            }
            .then(on: self.backgroundQ)
            {
                (preferDatabase: Bool) -> Promise<Void> in
                
                if preferDatabase
                {
                    self.resetLocal(tree: databaseRoot)
                    return Promise()
                }
                else
                {
                    return self.database.reset(tree: storeRoot)
                }
            }
        }
        .done
        {
            self.hasUnsyncedLocalChanges.value = false
        }
    }
    
    private var hasUnsyncedLocalChanges = PersistentFlag("UserDefaultsKeyUnsyncedLocalChanges",
                                                         default: true)
    
    // MARK: - Abort Intending to Sync When Errors Occur
    
    private func abortIntendingToSync(with error: Error)
    {
        abortIntendingToSync(withErrorMessage: error.message)
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
        
        firstly
        {
            Dialog.default.pose(question, imageName: "icloud_conflict")
        }
        .catch
        {
            log(error: $0.message)
        }
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

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
        
        observe(database.isReachable)
        {
            [weak self] in self?.databaseReachabilityDid(update: $0)
        }
        
        observeDatabase()
        observeStore()
    }
    
    deinit { stopObserving() }
    
    // MARK: - App Life Cycle
    
    func appDidLaunch()
    {
        guard loadItems(from: file), isIntendingToSync else { return }
        
        firstly
        {
            () -> Promise<Void> in
        
            return firstly
            {
                self.startIntendingToSync()
            }
            .done(on: self.backgroundQ)
            {
                if case .unavailable(let message) = $0
                {
                    self.abortIntendingToSync(withErrorMessage: message)
                }
            }
        }
        .catch(abortIntendingToSync)
    }
    
    func windowLostFocus() { saveItems(to: file) }
    
    func appWillTerminate() { saveItems(to: file) }
    
    // MARK: - Database Accessibility
    
    func databaseAccessibilityMayHaveChanged()
    {
        guard isIntendingToSync else { return }
        
        if database.isAccessible.value != true
        {
            log(error: "Invalid state: Using database while it's POSSIBLY inaccessible: Is accessible: \(String(describing: database.isAccessible))")
        }
    
        firstly
        {
            database.checkAccess()
        }
        .done(on: self.backgroundQ)
        {
            if case .inaccessible(let message) = $0
            {
                let c2a = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
                
                self.abortIntendingToSync(withErrorMessage: message, callToAction: c2a)
            }
            else if self.hasUnsyncedLocalChanges.value
            {
                self.doInitialSync().catch(self.abortIntendingToSync)
            }
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Network Reachability
    
    func databaseReachabilityDid(update: Change<Bool?>)
    {
        guard isIntendingToSync,
            let isReachable = update.new,
            let wasReachable = update.old,
            isReachable != wasReachable
        else { return }
        
        guard isReachable else
        {
            hasUnsyncedLocalChanges.value = true
            return
        }
        
        firstly
        {
            startIntendingToSync()
        }
        .done(on: backgroundQ)
        {
            if case .unavailable(let message) = $0
            {
                let c2a = "Seems like this device just went online but iCloud is unavailable. Make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
                
                self.abortIntendingToSync(withErrorMessage: message, callToAction: c2a)
            }
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Start and Stop the Intention to Sync
    
    func toggleIntentionToSyncWithDatabase()
    {
        if isIntendingToSync
        {
            syncIntentionPersistentFlag.value = false
        }
        else
        {
            firstly
            {
                startIntendingToSync()
            }
            .done(on: backgroundQ)
            {
                if case .unavailable(let message) = $0
                {
                    self.abortIntendingToSync(withErrorMessage: message)
                }
            }
            .catch(abortIntendingToSync)
        }
    }
    
    private func startIntendingToSync() -> Promise<SyncStartResult>
    {
        guard Store.shared.root != nil else
        {
            return Promise(error: StorageError.message("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            database.checkAccess()
        }
        .then(on: backgroundQ)
        {
            (availability: Accessibility) -> Promise<SyncStartResult> in
            
            switch availability
            {
            case .accessible:
                return firstly
                {
                    self.doInitialSync()
                }
                .map(on: self.backgroundQ)
                {
                    self.syncIntentionPersistentFlag.value = true
                    self.hasUnsyncedLocalChanges.value = false
                    
                    return .success
                }
                
            case .inaccessible(let message):
                return Promise.value(.unavailable(message))
            }
        }
    }
    
    private enum SyncStartResult
    {
        case success, unavailable(_ message: String)
    }
    
    private func doInitialSync() -> Promise<Void>
    {
        guard let storeRoot = Store.shared.root else
        {
            return Promise(error: StorageError.message("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        guard database.isReachable.value != false else
        {
            return Promise(error: StorageError.message("This device seems to be offline."))
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
    }
    
    private func resetLocal(tree: Item)
    {
        Store.shared.update(root: tree)
        file.save(tree)
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
    
    private func observeStore()
    {
        observe(Store.shared)
        {
            [weak self] in
            
            guard let self = self,
                case .didUpdate(let update) = $0,
                let edit = update.makeEdit() else { return }
            
            self.storeWasEdited(edit)
        }
    }
    
    private func storeWasEdited(_ edit: Edit)
    {
        // log("applying edit from store to db: \(edit)")
        
        guard database.isReachable.value != false, isIntendingToSync else
        {
            hasUnsyncedLocalChanges.value = true
            return
        }
        
        if database.isAccessible.value != true
        {
            hasUnsyncedLocalChanges.value = true

            if database.isCheckingAccess
            {
                return
            }
            else
            {
                let errorMessage = "Tried to edit iCloud database before ensuring accessibility."

                abortIntendingToSync(with: StorageError.message(errorMessage))
            }
        }
        
        database.apply(edit).catch
        {
            self.hasUnsyncedLocalChanges.value = true
            
            self.abortIntendingToSync(with: $0)
        }
    }
    
    private var hasUnsyncedLocalChanges = PersistentFlag(key: "UserDefaultsKeyUnsyncedLocalChanges",
                                                         default: false)
    
    // MARK: - Intention to Sync
    
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
    
    var isIntendingToSync: Bool { return syncIntentionPersistentFlag.value }
    
    private var syncIntentionPersistentFlag = PersistentFlag(key: "UserDefaultsKeyWantsToUseICloud",
                                                             default: true)
    
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
    
    // MARK: - File
    
    @discardableResult
    private func saveItems(to file: ItemFile?) -> Bool
    {
        guard let file = file else
        {
            log(error: "File is nil.")
            return false
        }
        
        guard let root = Store.shared.root else
        {
            log(error: "Store root is nil.")
            return false
        }
        
        file.save(root)
        return true
    }
    
    @discardableResult
    private func loadItems(from file: ItemFile?) -> Bool
    {
        guard let file = file else
        {
            log(error: "File is nil.")
            return false
        }
        
        guard let item = file.loadItem() else
        {
            log(error: "Couldn't load items from file.")
            return false
        }
        
        Store.shared.update(root: item)
        return true
    }
    
    // MARK: - Basics
    
    private var backgroundQ: DispatchQueue
    {
        return DispatchQueue.global(qos: .background)
    }
    
    let database: ItemDatabase
    let file: ItemFile
}

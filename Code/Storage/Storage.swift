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
        firstly
        {
            Store.shared.loadItems(from: file)
        }
        .then(on: backgroundQ)
        {
            _ -> Promise<Void> in
            
            guard self.intendsToSync else { return Promise() }
        
            return firstly
            {
                self.startIntendingToSync()
            }
            .done(on: self.backgroundQ)
            {
                if case .unavailable(let message) = $0
                {
                    self.abortIntendingToSync(errorMessage: message)
                }
            }
        }
        .catch(abortIntendingToSync)
    }
    
    func windowLostFocus() { Store.shared.saveItems(to: file) }
    
    func appWillTerminate() { Store.shared.saveItems(to: file) }
    
    // MARK: - Database Availability
    
    func databaseAvailabilityMayHaveChanged()
    {
        guard self.intendsToSync else { return }
        
        if database.isAccessible != true
        {
            log(error: "Invalid state: Using database while it's POSSIBLY unavailable: Is availabe: \(String(describing: database.isAccessible))")
        }
    
        firstly
        {
            database.ensureAccess()
        }
        .done(on: self.backgroundQ)
        {
            if case .unaccessible(let message) = $0
            {
                let c2a = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account and iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
                
                self.abortIntendingToSync(errorMessage: message, callToAction: c2a)
            }
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Network Reachability
    
    func databaseReachabilityDid(update: Change<Bool?>)
    {
        guard intendsToSync,
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
                
                self.abortIntendingToSync(errorMessage: message, callToAction: c2a)
            }
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Start and Abort the Intention to Sync
    
    var intendsToSync: Bool
    {
        set
        {
            guard newValue else
            {
                _intendsToSync.value = false
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
                    self.abortIntendingToSync(errorMessage: message)
                }
            }
            .catch(abortIntendingToSync)
        }
        
        get { return _intendsToSync.value }
    }
    
    private func startIntendingToSync() -> Promise<SyncStartResult>
    {
        guard Store.shared.root != nil else
        {
            return Promise(error: StorageError.message("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            database.ensureAccess()
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
                    self._intendsToSync.value = true
                    self.hasUnsyncedLocalChanges.value = false
                    
                    return .success
                }
                
            case .unaccessible(let message):
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
                
                return self.resetLocal(tree: databaseRoot)
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
                
                return self.resetLocal(tree: databaseRoot)
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
                    return self.resetLocal(tree: databaseRoot)
                }
                else
                {
                    return self.database.reset(tree: storeRoot)
                }
            }
        }
    }
    
    private func resetLocal(tree: Item) -> Promise<Void>
    {
        return firstly
        {
            Store.shared.update(root: tree)
        }
        .done(on: self.backgroundQ)
        {
            self.file.save(tree)
        }
    }
    
    // MARK: - Observe Database & Store

    private func observeDatabase()
    {
        let databaseMessenger = database.messenger
        
        observe(databaseMessenger)
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
            guard case .wasEdited(let edit) = $0 else { return }
            
            self.storeWasEdited(edit)
        }
    }
    
    private func storeWasEdited(_ edit: Edit)
    {
        // log("applying edit from store to db: \(edit)")
        
        guard database.isReachable.value != false else
        {
            hasUnsyncedLocalChanges.value = true
            return
        }
        
        guard database.isAccessible == true else
        {
            hasUnsyncedLocalChanges.value = true
            
            log(error: "Invalid state: Applying store edits to database while database is unavailable.")
            
            return
        }
        
        database.apply(edit).catch
        {
            self.hasUnsyncedLocalChanges.value = true
            
            self.abortIntendingToSync(with: $0)
        }
    }
    
    private var hasUnsyncedLocalChanges = PersistentFlag(key: "UserDefaultsKeyUnsyncedLocalChanges",
                                                         default: false)
    
    // MARK: - Abort Syncing
    
    private func abortIntendingToSync(with error: Error)
    {
        abortIntendingToSync(errorMessage: error.message)
    }
    
    private func abortIntendingToSync(errorMessage error: String,
                                      callToAction: String? = nil)
    {
        _intendsToSync.value = false
        
        log(error: error)
        
        let c2a = callToAction ?? "Make sure that 1) Your Mac is online, 2) It is connected to your iCloud account and 3) iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
        
        informUserAboutSyncProblem(error: error, callToAction: c2a)
    }
    
    private var _intendsToSync = PersistentFlag(key: "IsUsingDatabase",
                                                default: true)
    
    private func informUserAboutSyncProblem(error: String,
                                            callToAction: String)
    {
        let question = Dialog.Question(title: "Whoops, Had to Pause iCloud Sync",
                                       text: "\(error)\n\n\(callToAction)",
                                       options: ["Got it"])
        
        Dialog.default.pose(question,
                            imageName: "icloud_conflict").catch { _ in }
    }
    
    // MARK: - Basics
    
    private var backgroundQ: DispatchQueue
    {
        return DispatchQueue.global(qos: .background)
    }
    
    let database: ItemDatabase
    let file: ItemFile
}

fileprivate extension Error
{
    var message: String
    {
        if let error = self as? StorageError
        {
            switch error
            {
            case .message(let text): return text
            }
        }
        else
        {
            return "This issue came up: \(String(describing: self))"
        }
    }
}

import SwiftObserver
import PromiseKit

class Storage: Observer
{
    // MARK: - Initialize
    
    init(with file: ItemFile, database: ItemDatabase)
    {
        self.file = file
        self.database = database
    }
    
    // MARK: - App Life Cycle
    
    func appDidLaunch()
    {
        Store.shared.loadItems(from: file)

        guard intendsToSync else { return }
        
        firstly
        {
            startSyncing()
        }
        .done
        {
            if case .unavailable(let message) = $0
            {
                self.abortIntendingToSync(errorMessage: message)
            }
        }
        .catch
        {
            self._intendsToSync.value = false
            self.stopObservingDatabaseAndStore()
            log($0)
        }
    }
    
    func windowLostFocus() { Store.shared.saveItems(to: file) }
    
    func appWillTerminate() { Store.shared.saveItems(to: file) }
    
    // MARK: - iCloud Availability
    
    func databaseAvailabilityMayHaveChanged()
    {
        guard self.intendsToSync else { return }
        
        if database.isAvailable != true
        {
            log(error: "Invalid state: Using database while it's POSSIBLY unavailable: Is availabe: \(String(describing: database.isAvailable))")
        }
    
        firstly
        {
            database.checkAvailability()
        }
        .done
        {
            if case .unavailable(let message) = $0
            {
                let c2a = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account, then select the menu option \"Data → Start Using iCloud\"."
                
                self.abortIntendingToSync(errorMessage: message, callToAction: c2a)
            }
        }
        .catch
        {
            self._intendsToSync.value = false
            self.stopObservingDatabaseAndStore()
            log($0)
        }
    }
    
    // MARK: - Network Reachability
    
    func networkBecame(reachable: Bool)
    {
        defer { networkIsReachable = reachable }
        
        guard intendsToSync,
            let wasReachable = networkIsReachable,
            wasReachable != reachable
        else
        {
            return
        }
        
        guard reachable else
        {
            stopObservingDatabaseAndStore()
            return
        }

        firstly
        {
            startSyncing()
        }
        .done
        {
            if case .unavailable(let message) = $0
            {
                let c2a = "The device just went online but iCloud is unavailable. Make sure your Mac is connected to your iCloud account, then retry activating iCloud via the menu option \"Data → Start Using iCloud\"."
                
                self.abortIntendingToSync(errorMessage: message, callToAction: c2a)
            }
        }
        .catch
        {
            self._intendsToSync.value = false
            self.stopObservingDatabaseAndStore()
            log($0)
        }
    }
    
    private var networkIsReachable: Bool?
    
    // MARK: - Opting In and Out of Syncing
    
    var intendsToSync: Bool
    {
        set
        {
            guard newValue else
            {
                _intendsToSync.value = false
                stopObservingDatabaseAndStore()
                return
            }
            
            firstly
            {
                startSyncing()
            }
            .done
            {
                if case .unavailable(let message) = $0
                {
                    self.abortIntendingToSync(errorMessage: message)
                }
            }
            .catch
            {
                self._intendsToSync.value = false
                self.stopObservingDatabaseAndStore()
                log($0)
            }
        }
        
        get { return _intendsToSync.value }
    }
    
    // MARK: - Initiate and Abort Syncing
    
    private func startSyncing() -> Promise<SyncStartResult>
    {
        guard Store.shared.root != nil else
        {
            return Promise(error: StorageError.storeHasNoRoot("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
        
        return firstly
        {
            database.checkAvailability()
        }
        .then
        {
            (availability: Availability) -> Promise<SyncStartResult> in
            
            switch availability
            {
            case .available:
                return firstly
                {
                    self.doInitialSync()
                }
                .map
                {
                    self._intendsToSync.value = true
                    self.startObservingDatabaseAndStore()
                    
                    return .success
                }
                
            case .unavailable(let message):
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
            return Promise(error: StorageError.storeHasNoRoot("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
            
        return firstly
        {
            self.database.fetchTrees()
        }
        .then
        {
            (roots: [Item]) -> Promise<Void> in
            
            guard let databaseRoot = roots.first else
            {
                // no items in database
                
                return self.database.resetItemTree(with: storeRoot)
            }
            
            if storeRoot.isLeaf && !databaseRoot.isLeaf
            {
                // no user items in Store but in iCloud
                
                Store.shared.update(root: databaseRoot)
                self.file.save(databaseRoot)
                
                return Promise()
            }
            
            if storeRoot.isIdentical(to: databaseRoot)
            {
                // Store and iCloud are identical
                
                return Promise()
            }
            
            return firstly
            {
                self.database.fetchUpdates()
            }
            .then
            {
                (edits: [Edit]) -> Promise<Void> in
                
                // TODO: how do we know the store actually changed since the last sync?
                
                if edits.isEmpty
                {
                    // Store changed but noone changed iCloud
                    
                    return self.database.resetItemTree(with: storeRoot)
                }
                
                // conflicting item trees
                
                return firstly
                {
                    Dialog.default.askWhetherToPreferICloud()
                }
                .then
                {
                    (preferICloud: Bool) -> Promise<Void> in
                    
                    if preferICloud
                    {
                        Store.shared.update(root: databaseRoot)
                        self.file.save(databaseRoot)
                        return Promise()
                    }
                    else
                    {
                        return self.database.resetItemTree(with: storeRoot)
                    }
                }
            }
        }
    }
    
    private func abortIntendingToSync(errorMessage error: String,
                                      callToAction: String? = nil)
    {
        let c2a = callToAction ?? "Make sure your Mac is connected to your iCloud account, then retry activating iCloud via the menu option \"Data → Start Using iCloud\"."
        
        stopObservingDatabaseAndStore()
        _intendsToSync.value = false
        informUserAboutSyncProblem(error: error, callToAction: c2a)
    }
    
    // MARK: - Observe Database & Store
    
    private func startObservingDatabaseAndStore()
    {
        self.observeDatabase()
        self.observeStore()
    }
    
    private func stopObservingDatabaseAndStore()
    {
        stopObservingDatabase()
        stopObserving(Store.shared)
    }
    
    private func observeDatabase()
    {
        let databaseMessenger = database.messenger
        
        observe(databaseMessenger)
        {
            guard let edit = $0 else { return }
            
            //log("applying edit from db to store: \(edit)")
            
            Store.shared.apply(edit)
        }
    }
    
    private func stopObservingDatabase()
    {
        stopObserving(database.messenger)
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
        //log("applying edit from store to db: \(edit)")
        
        guard database.isAvailable == true else
        {
            log(error: "Invalid state: Applying store edits to database while database is unavailable.")
            return
        }
        
        database.apply(edit)
    }
    
    // MARK: - Database
    
    private func informUserAboutSyncProblem(error: String,
                                            callToAction: String)
    {
        log("Flowlist could not use iCloud. This issue occured: \(error)\n\(callToAction)\n\n",
            title: "Whoops, no iCloud?",
            forUser: true)
    }
    
    private var _intendsToSync = PersistentFlag(key: "IsUsingDatabase",
                                                defaultValue: true)
    
    let database: ItemDatabase
    
    // MARK: - File
    
    let file: ItemFile
    
    // MARK: - Errors
    
    private enum StorageError: Error
    {
        case storeHasNoRoot(_ message: String)
    }
}

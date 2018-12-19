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
                let c2a = "Looks like you lost iCloud access. If you'd like to continue syncing devices via iCloud, make sure your Mac is connected to your iCloud account, then select the menu option \"Data → Start Using iCloud\"."
                
                self.abortIntendingToSync(errorMessage: message, callToAction: c2a)
            }
        }
        .catch(abortIntendingToSync)
    }
    
    // MARK: - Network Reachability
    
    func databaseReachabilityDid(update: Change<Bool?>)
    {
        guard intendsToSync,
            let new = update.new,
            let old = update.old,
            new != old
        else { return }
        
        guard new else
        {
            stopObservingDatabaseAndStore()
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
                let c2a = "Seem like this device just went online but iCloud is unavailable. Make sure your Mac is connected to your iCloud account, then retry activating iCloud via the menu option \"Data → Start Using iCloud\"."
                
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
                stopObservingDatabaseAndStore()
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
            return Promise(error: StorageError.storeHasNoRoot("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
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
                    // FIXME: going from this result to the map closure takes pretty fuckin long and freezes the app
                    /* Remaining Points to Tackle:
                     * Many Item object are being deallocated cause some closure context deallocates...
                     * The deallocation unneccessarily calls stopObserving while the observed items probably also must be deallocated anyway...
                     */
                    self.doInitialSync()
                }
                .map(on: self.backgroundQ)
                {
                    self._intendsToSync.value = true
                    self.startObservingDatabaseAndStore()
                    
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
            return Promise(error: StorageError.storeHasNoRoot("Create file and Store root before syncing Store with Database! file \(#file) line \(#line)"))
        }
            
        return firstly
        {
            // TODO: This takes pretty fuckin long
            self.database.fetchTrees()
        }
        .then(on: backgroundQ)
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
                
                return firstly
                {
                    Store.shared.update(root: databaseRoot)
                }
                .done(on: self.backgroundQ)
                {
                    self.file.save(databaseRoot)
                }
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
            .then(on: self.backgroundQ)
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
                .then(on: self.backgroundQ)
                {
                    (preferICloud: Bool) -> Promise<Void> in
                    
                    if preferICloud
                    {
                        return firstly
                        {
                            Store.shared.update(root: databaseRoot)
                        }
                        .done(on: self.backgroundQ)
                        {
                            self.file.save(databaseRoot)
                        }
                    }
                    else
                    {
                        return self.database.resetItemTree(with: storeRoot)
                    }
                }
            }
        }
    }
    
    private func abortIntendingToSync(with error: Error)
    {
        let errorMessage = String(describing: error)
        log(error: errorMessage)
        abortIntendingToSync(errorMessage: errorMessage)
    }
    
    private func abortIntendingToSync(errorMessage error: String,
                                      callToAction: String? = nil)
    {
        let c2a = callToAction ?? "Make sure your Mac is connected to your iCloud account, then try resuming iCloud sync via the menu:\nData → Start Using iCloud"
        
        stopObservingDatabaseAndStore()
        _intendsToSync.value = false
        informUserAboutSyncProblem(error: error, callToAction: c2a)
    }
    
    private var _intendsToSync = PersistentFlag(key: "IsUsingDatabase",
                                                default: true)
    
    private func informUserAboutSyncProblem(error: String, callToAction: String)
    {
        log(error: "iCloud sync failed: \(error)\nc2a: \(callToAction)")
        
        let question = Dialog.Question(title: "Whoops, Had to Pause iCloud Sync",
                                       text: "This issue came up: \(error)\n\n\(callToAction)",
                                       options: ["Got it"])
        
        Dialog.default.pose(question,
                            imageName: "icloud_conflict").catch { _ in }
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
        
        guard database.isAccessible == true else
        {
            log(error: "Invalid state: Applying store edits to database while database is unavailable.")
            return
        }
        
        database.apply(edit)
    }
    
    // MARK: - Basics
    
    private var backgroundQ: DispatchQueue
    {
        return DispatchQueue.global(qos: .background)
    }
    
    let database: ItemDatabase
    let file: ItemFile
    
    private enum StorageError: Error
    {
        case storeHasNoRoot(_ message: String)
    }
}

import CloudKit
import FoundationToolz
import PromiseKit
import SwiftObserver
import SwiftyToolz

class CKRecordController: Observer
{
    // MARK: - Life Cycle

    init()
    {
        observeCKRecordDatabase()
        observeFileDatabase()
        
        NetworkReachability.shared.add(observer: self)
        {
            [weak self] in self?.networkReachability(did: $0)
        }
    }
    
    deinit
    {
        stopObserving()
        NetworkReachability.shared.remove(observer: self)
    }
    
    // MARK: - Forward Database Messages to Synchronizer
    
    private func observeCKRecordDatabase()
    {
        observe(CKRecordDatabase.shared).select(.mayHaveChanged)
        {
            [weak self] in self?.synchronizer.ckRecordDatabaseMayHaveChanged()
        }
    }
    
    private func observeFileDatabase()
    {
        observe(FileDatabase.shared).unwrap().filter
        {
            [weak self] event in self != nil
                && event.object !== self?.synchronizer
                && event.object !== self?.synchronizer.editor
        }
        .receive
        {
            [weak self] event in self?.synchronizer.fileDatabase(did: event.did)
        }
    }
    
    // MARK: - React to Events
    
    private func networkReachability(did update: NetworkReachability.Update)
    {
        switch update
        {
        case .noInternet: synchronizer.isOnline = false
        case .expensiveInternet, .fullInternet: synchronizer.isOnline = true
        }
    }
    
    func accountDidChange()
    {
        synchronizer.resync()
    }
    
    func userDidToggleSync()
    {
        synchronizer.toggleSync()
    }

    // MARK: - Synchronizer
    
    func resync() -> Promise<Void> { synchronizer.resyncAsynchronously() }
    private let synchronizer = CKRecordSynchronizer()
}

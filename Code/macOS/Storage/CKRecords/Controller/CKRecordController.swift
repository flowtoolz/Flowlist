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
        observe(FileDatabase.shared).filter
        {
            [weak self] in $0 != nil && $0?.object !== self
        }
        .map
        {
            event in event?.did
        }
        .unwrap(.saveRecords([]))
        {
            // TODO: make network reachability a shared singleton instead of holding the value here and passing it around
            [weak self] edit in self?.synchronizer.fileDatabase(did: edit)
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

    // MARK: - Basics: Synchronizer & Editor
    
    func resync() -> Promise<Void> { return synchronizer.resyncAsynchronously() }
    private let synchronizer = CKRecordSynchronizer()
}

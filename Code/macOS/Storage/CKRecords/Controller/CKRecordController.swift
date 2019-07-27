import CloudKit
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
    }
    
    deinit { stopObserving() }
    
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
            [weak self] edit in self?.synchronizer.fileDatabase(did: edit,
                                                                isOnline: self?.isOnline ?? true)
        }
    }
    
    // MARK: - React to Events
    
    func accountDidChange()
    {
        synchronizer.resyncCatchingErrors()
    }
    
    func userDidToggleSync()
    {
        synchronizer.toggleSync()
    }
    
    func networkReachabilityDidUpdate(isReachable: Bool)
    {
        let reachabilityDidChange = isOnline != nil && isOnline != isReachable
        isOnline = isReachable

        if reachabilityDidChange && isReachable // went online
        {
            synchronizer.resyncCatchingErrors()
        }
    }
    
    var isOnline: Bool?

    // MARK: - Basics: Synchronizer & Editor
    
    func resync() -> Promise<Void> { return synchronizer.resync() }
    func abortSync(with error: Error) { synchronizer.abortSync(with: error) }
    var syncIsActive: Bool { return synchronizer.syncIsActive }
    private let synchronizer = CKRecordSynchronizer()
    
    private let editor = CKRecordEditor()
}

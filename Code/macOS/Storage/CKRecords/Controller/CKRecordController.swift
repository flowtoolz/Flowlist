import CloudKit
import FoundationToolz
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
        observe(FileDatabase.shared).notFrom(synchronizer).notFrom(synchronizer.editor)
        {
            [weak self] in self?.synchronizer.fileDatabaseDidSend($0)
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
    
    func toggleSync()
    {
        synchronizer.toggleSync()
    }

    // MARK: - Synchronizer
    
    func resync() -> ResultPromise<Void> { synchronizer.resyncAsynchronously() }
    private let synchronizer = CKRecordSynchronizer()
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

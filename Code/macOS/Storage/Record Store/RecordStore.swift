import PromiseKit
import SwiftObserver

class RecordStore: Observer, CustomObservable
{
    func fetchChanges() -> Promise<Void>
    {
        return firstly
        {
            cloudDatabase.fetchChanges()
        }
        .done(on: cloudDatabase.queue)
        {
            // TODO: also apply changes to local db (file system)
            self.send(.didApplyRecordChanges($0))
        }
    }
    
    // MARK: - Life Cycle
    
    init(localDatabase: LocalDatabase, cloudDatabase: CloudDatabase)
    {
        self.localDatabase = localDatabase
        
        self.cloudDatabase = cloudDatabase
        
        observe(cloudDatabase.messenger).select(.mayHaveChanged)
        {
            [weak self] in self?.send(.cloudDatabaseDidChange)
        }
    }
    
    deinit { stopObserving() }
    
    // MARK: - Local- and Cloud Database
    
    var queue: DispatchQueue { return cloudDatabase.queue }
    
    let localDatabase: LocalDatabase
    let cloudDatabase: CloudDatabase
    
    // MARK: - Observability
    
    let messenger = Messenger<Event?>()
    typealias Message = Event?
    
    enum Event: Equatable
    {
        case cloudDatabaseDidChange
        case didDeleteRecordsWithIDs([String])
        case didUpdateRecords([Record])
        case didApplyRecordChanges(RecordChanges)
    }
}

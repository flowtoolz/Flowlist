import SwiftObserver

class RecordStore: CustomObservable
{
    // MARK: - Life Cycle
    
    static let shared = RecordStore()
    private init() {}
    
    // MARK: - Manage Records

    func record(for id: Record.ID) -> Record?
    {
        return records[id]
    }
    
    func save(_ recordsToSave: [Record])
    {
        recordsToSave.forEach { records[$0.id] = $0 }
        
        // TODO: POSIIBLY only send those that actually changed, if any changed at all
        send(.didSaveRecords(recordsToSave))
    }
    
    func deleteRecords(with ids: [Record.ID])
    {
        ids.forEach { records[$0] = nil }
        
        // TODO: POSIIBLY only send those that actually existed, if any existed at all
        send(.didDeleteRecordsWithIDs(ids))
    }
    
    private var records = [Record.ID : Record]()
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    
    enum Event
    {
        case didDeleteRecordsWithIDs([Record.ID])
        case didSaveRecords([Record])
    }
}

import SwiftObserver

class RecordStore: CustomObservable
{
    // MARK: - Life Cycle
    
    static let shared = RecordStore()
    private init() {}
    
    // MARK: - Change Records
    
    func save(_ records: [Record])
    {
        let differingRecords = records.compactMap { recordsByID[$0.id] != $0 ? $0 : nil }
        differingRecords.forEach { recordsByID[$0.id] = $0 }
        send(.didMofifyRecords(differingRecords))
    }
    
    func deleteRecords(with ids: [Record.ID])
    {
        let idsOfExistingRecords = ids.compactMap { recordsByID[$0] != nil ? $0 : nil }
        idsOfExistingRecords.forEach { recordsByID[$0] = nil }
        send(.didDeleteRecordsWithIDs(idsOfExistingRecords))
    }
    
    private var recordsByID = [Record.ID : Record]()
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    
    enum Event
    {
        case didMofifyRecords([Record])
        case didDeleteRecordsWithIDs([Record.ID])
    }
}

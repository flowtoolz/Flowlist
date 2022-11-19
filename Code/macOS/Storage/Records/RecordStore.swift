import SwiftObserver

class RecordStore: ObservableObject
{
    // MARK: - Life Cycle
    
    static let shared = RecordStore()
    private init() {}
    
    // MARK: - Change Records
    
    func save(_ records: [Record], as author: AnyAuthor)
    {
        guard !records.isEmpty else { return }
        let differingRecords = records.compactMap { recordsByID[$0.id] != $0 ? $0 : nil }
        guard !differingRecords.isEmpty else { return }
        differingRecords.forEach { recordsByID[$0.id] = $0 }
        send(.didModifyRecords(differingRecords), from: author)
    }
    
    func deleteRecords(with ids: [Record.ID], as author: AnyAuthor)
    {
        guard !ids.isEmpty else { return }
        let idsOfExistingRecords = ids.compactMap { recordsByID[$0] != nil ? $0 : nil }
        guard !idsOfExistingRecords.isEmpty else { return }
        idsOfExistingRecords.forEach { recordsByID[$0] = nil }
        send(.didDeleteRecordsWithIDs(idsOfExistingRecords), from: author)
    }
    
    private var recordsByID = [Record.ID : Record]()
    
    // MARK: - Observability
    
    let messenger = Messenger<Event>()
    
    enum Event
    {
        case didModifyRecords([Record])
        case didDeleteRecordsWithIDs([Record.ID])
    }
}

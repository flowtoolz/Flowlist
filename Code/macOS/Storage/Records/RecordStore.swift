import SwiftObserver

class RecordStore: CustomObservable
{
    // MARK: - Life Cycle
    
    static let shared = RecordStore()
    private init() {}
    
    // MARK: - Change Records
    
    func save(_ records: [Record], identifyAs object: AnyObject)
    {
        let differingRecords = records.compactMap { recordsByID[$0.id] != $0 ? $0 : nil }
        guard !differingRecords.isEmpty else { return }
        differingRecords.forEach { recordsByID[$0.id] = $0 }
        send((object, did: .modifyRecords(differingRecords)))
    }
    
    func deleteRecords(with ids: [Record.ID], identifyAs object: AnyObject)
    {
        let idsOfExistingRecords = ids.compactMap { recordsByID[$0] != nil ? $0 : nil }
        guard !idsOfExistingRecords.isEmpty else { return }
        idsOfExistingRecords.forEach { recordsByID[$0] = nil }
        send((object, did: .deleteRecordsWithIDs(idsOfExistingRecords)))
    }
    
    private var recordsByID = [Record.ID : Record]()
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    
    typealias Event = (object: AnyObject, did: Edit)
    
    enum Edit
    {
        case modifyRecords([Record])
        case deleteRecordsWithIDs([Record.ID])
    }
}
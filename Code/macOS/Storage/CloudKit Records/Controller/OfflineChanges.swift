class OfflineChanges
{
    static let shared = OfflineChanges()
    private init() {}
    
    var hasChanges: Bool
    {
        return !idsOfSavedRecords.isEmpty || !idsOfDeletedRecords.isEmpty
    }
    
    func save(_ records: [Record])
    {
        let ids = records.map { $0.id }
        
        ids.forEach
        {
            idsOfDeletedRecords.remove($0)
            idsOfSavedRecords.insert($0)
        }
    }
    
    func deleteRecords(with ids: [Record.ID])
    {
        ids.forEach
        {
            idsOfSavedRecords.remove($0)
            idsOfDeletedRecords.insert($0)
        }
    }
    
    // TODO: persist changes in files
    private(set) var idsOfSavedRecords = Set<Record.ID>()
    private(set) var idsOfDeletedRecords = Set<Record.ID>()
}

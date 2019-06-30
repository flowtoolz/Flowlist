protocol RecordPersister: AnyObject
{
    @discardableResult
    func save(_ records: [Record]) -> Bool
    
    func loadRecords() -> [Record]
}

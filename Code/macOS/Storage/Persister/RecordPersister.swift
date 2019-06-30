protocol RecordPersister: AnyObject
{
    func save(_ records: [Record])
    func loadRecords() -> [Record]
}

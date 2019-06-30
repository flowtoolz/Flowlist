protocol RecordPersister: AnyObject
{
    //func save(_ records: [Record])
    func loadRecords() -> [Record]
    
    /// deprecated
    func save(_ item: Item)
}

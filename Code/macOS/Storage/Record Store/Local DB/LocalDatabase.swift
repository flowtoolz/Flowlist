protocol LocalDatabase: AnyObject
{
    @discardableResult
    func save(_ records: [Record]) -> Bool
    
    func loadRecords() -> [Record]
}

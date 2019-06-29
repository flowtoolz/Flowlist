protocol ItemFile: AnyObject
{
    func save(_ item: Item)
    func loadRecords() -> [Record]
}

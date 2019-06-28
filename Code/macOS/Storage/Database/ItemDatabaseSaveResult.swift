// TODO: ultimately reduce these types to what the storage model really needs

struct ItemDatabaseSaveResult
{
    static var empty: ItemDatabaseSaveResult
    {
        return ItemDatabaseSaveResult(successes: [], conflicts: [], failures: [])
    }
    
    let successes: [Record]
    let conflicts: [ItemDatabaseSaveConflict]
    let failures: [ItemDatabaseSaveFailure]
}

struct ItemDatabaseSaveConflict
{
    let clientRecord: Record
    let serverRecord: Record
    let ancestorRecord: Record?
}

struct ItemDatabaseSaveFailure
{
    init(_ record: Record, _ error: Error)
    {
        self.record = record
        self.error = error
    }
    
    let record: Record
    let error: Error
}

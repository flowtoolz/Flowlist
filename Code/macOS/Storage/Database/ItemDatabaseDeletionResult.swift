// TODO: ultimately reduce these types to what the storage model really needs

struct ItemDatabaseDeletionResult
{
    static var empty: ItemDatabaseDeletionResult
    {
        return ItemDatabaseDeletionResult(idsOfDeletedRecords: [], failures: [])
    }
    
    let idsOfDeletedRecords: [String]
    let failures: [ItemDatabaseDeletionFailure]
}

struct ItemDatabaseDeletionFailure
{
    let recordID: String
    let error: Error
}

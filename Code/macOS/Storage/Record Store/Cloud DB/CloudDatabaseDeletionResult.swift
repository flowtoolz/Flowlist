// TODO: ultimately reduce these types to what the storage model really needs

struct CloudDatabaseDeletionResult
{
    static var empty: CloudDatabaseDeletionResult
    {
        return CloudDatabaseDeletionResult(idsOfDeletedRecords: [], failures: [])
    }
    
    let idsOfDeletedRecords: [String]
    let failures: [CloudDatabaseDeletionFailure]
}

struct CloudDatabaseDeletionFailure
{
    let recordID: String
    let error: Error
}

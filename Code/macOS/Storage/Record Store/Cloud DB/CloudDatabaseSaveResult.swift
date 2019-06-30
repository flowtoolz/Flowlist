// TODO: ultimately reduce these types to what the storage model really needs

struct CloudDatabaseSaveResult
{
    static var empty: CloudDatabaseSaveResult
    {
        return CloudDatabaseSaveResult(successes: [], conflicts: [], failures: [])
    }
    
    let successes: [Record]
    let conflicts: [CloudDatabaseSaveConflict]
    let failures: [CloudDatabaseSaveFailure]
}

struct CloudDatabaseSaveConflict
{
    let clientRecord: Record
    let serverRecord: Record
    let ancestorRecord: Record?
}

struct CloudDatabaseSaveFailure
{
    init(_ record: Record, _ error: Error)
    {
        self.record = record
        self.error = error
    }
    
    let record: Record
    let error: Error
}

class RecordStore
{
    init(localDatabase: LocalDatabase, cloudDatabase: CloudDatabase)
    {
        self.localDatabase = localDatabase
        self.cloudDatabase = cloudDatabase
    }
    
    let localDatabase: LocalDatabase
    let cloudDatabase: CloudDatabase
}

import CloudKit

extension ItemDatabaseChanges
{
    init(_ iCloudDatabaseChanges: ICloudDatabase.Changes)
    {
        idsOfDeletedRecords = iCloudDatabaseChanges.idsOfDeletedCKRecords.map { $0.recordName }
        modifiedRecords = iCloudDatabaseChanges.changedCKRecords.map(Record.init)
    }
}

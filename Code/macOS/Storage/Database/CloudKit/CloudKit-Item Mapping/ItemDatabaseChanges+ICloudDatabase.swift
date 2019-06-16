import CloudKit

extension ItemDatabaseChanges
{
    init(_ ckDatabaseChanges: CKDatabase.Changes)
    {
        idsOfDeletedRecords = ckDatabaseChanges.idsOfDeletedCKRecords.map { $0.recordName }
        modifiedRecords = ckDatabaseChanges.changedCKRecords.map(Record.init)
    }
}

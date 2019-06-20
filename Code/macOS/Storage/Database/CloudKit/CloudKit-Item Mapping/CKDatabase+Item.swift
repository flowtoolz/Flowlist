import CloudKit

extension CKDatabase.Changes
{
    func makeItemDatabaseChanges() -> ItemDatabaseChanges
    {
        let idsOfDeletedRecords = idsOfDeletedCKRecords.map { $0.recordName }
        let modifiedRecords = changedCKRecords.map { $0.makeItemRecord() }
        
        return ItemDatabaseChanges(modifiedRecords: modifiedRecords,
                                   idsOfDeletedRecords: idsOfDeletedRecords)
    }
}

import CloudKit
import CloudKid

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

extension CKDatabase.DeletionResult
{
    func makeItemDatabaseDeletionResult() -> ItemDatabaseDeletionResult
    {
        let idsOfDeletedRecords = successes.map { $0.recordName }
        
        let failures = self.failures.map
        {
            ItemDatabaseDeletionFailure(recordID: $0.recordID.recordName,
                                        error: $0.error)
        }
        
        return ItemDatabaseDeletionResult(idsOfDeletedRecords: idsOfDeletedRecords,
                                          failures: failures)
    }
}

extension CKDatabase.SaveResult
{
    func makeItemDatabaseSaveResult() -> ItemDatabaseSaveResult
    {
        let successes = self.successes.map
        {
            $0.makeItemRecord()
        }
        
        let failures = self.failures.map
        {
            ItemDatabaseSaveFailure($0.record.makeItemRecord(), $0.error)
        }
        
        let conflicts = self.conflicts.map
        {
            ItemDatabaseSaveConflict(clientRecord: $0.clientRecord.makeItemRecord(),
                                     serverRecord: $0.serverRecord.makeItemRecord(),
                                     ancestorRecord: $0.ancestorRecord?.makeItemRecord())
        }
        
        return ItemDatabaseSaveResult(successes: successes,
                                      conflicts: conflicts,
                                      failures: failures)
    }
}

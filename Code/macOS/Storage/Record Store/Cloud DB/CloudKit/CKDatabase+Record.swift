import CloudKit
import CloudKid

extension CKDatabase.Changes
{
    func makeCloudDatabaseChanges() -> CloudDatabaseChanges
    {
        let idsOfDeletedRecords = idsOfDeletedCKRecords.map { $0.recordName }
        let modifiedRecords = changedCKRecords.map { $0.makeRecord() }
        
        return CloudDatabaseChanges(modifiedRecords: modifiedRecords,
                                   idsOfDeletedRecords: idsOfDeletedRecords)
    }
}

extension CKDatabase.DeletionResult
{
    func makeCloudDatabaseDeletionResult() -> CloudDatabaseDeletionResult
    {
        let idsOfDeletedRecords = successes.map { $0.recordName }
        
        let failures = self.failures.map
        {
            CloudDatabaseDeletionFailure(recordID: $0.recordID.recordName,
                                        error: $0.error)
        }
        
        return CloudDatabaseDeletionResult(idsOfDeletedRecords: idsOfDeletedRecords,
                                          failures: failures)
    }
}

extension CKDatabase.SaveResult
{
    func makeCloudDatabaseSaveResult() -> CloudDatabaseSaveResult
    {
        let successes = self.successes.map
        {
            $0.makeRecord()
        }
        
        let failures = self.failures.map
        {
            CloudDatabaseSaveFailure($0.record.makeRecord(), $0.error)
        }
        
        let conflicts = self.conflicts.map
        {
            CloudDatabaseSaveConflict(clientRecord: $0.clientRecord.makeRecord(),
                                     serverRecord: $0.serverRecord.makeRecord(),
                                     ancestorRecord: $0.ancestorRecord?.makeRecord())
        }
        
        return CloudDatabaseSaveResult(successes: successes,
                                      conflicts: conflicts,
                                      failures: failures)
    }
}

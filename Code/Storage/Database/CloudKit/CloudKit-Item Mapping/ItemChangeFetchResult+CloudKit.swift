import CloudKit

extension ItemDatabaseChanges
{
    init(_ ckChangeFetchResult: CKChangeFetchResult)
    {
        if let clientToken = ckChangeFetchResult.clientChangeToken,
            let clientTokenString = String(data: clientToken, encoding: .utf8)
        {
            thisAppDidTheChanges = clientTokenString == appInstallationID
        }
        else
        {
            thisAppDidTheChanges = false
        }
        
        idsOfDeletedRecords = ckChangeFetchResult.idsOfDeletedCKRecords.map { $0.recordName }
        modifiedRecords = ckChangeFetchResult.changedCKRecords.map(Record.init)
    }
}

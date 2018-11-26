import CloudKit
import SwiftObserver

extension ChangeFetch
{
    convenience init(zoneID fetchZoneID: CKRecordZone.ID,
                     token: CKServerChangeToken?,
                     handleResult: @escaping (Result?) -> Void)
    {
        let zoneOptions = ChangeFetch.ZoneOptions()
        
        zoneOptions.previousServerChangeToken = token
        
        let options = [fetchZoneID : zoneOptions]

        self.init(recordZoneIDs: [fetchZoneID],
                  optionsByRecordZoneID: options)
        
        var changes = Result()
        
        recordChangedBlock =
        {
            record in changes.changedRecords.append(record)
        }
        
        recordWithIDWasDeletedBlock =
        {
            id, _ in changes.idsOfDeletedRecords.append(id)
        }
        
        recordZoneChangeTokensUpdatedBlock =
        {
            zoneID, serverToken, clientToken in
            
            guard zoneID == fetchZoneID else
            {
                log(error: "Unexpected zone: \(zoneID.zoneName)")
                return
            }
            
            if clientToken != nil
            {
                changes.clientChangeToken = clientToken
            }
            
            if serverToken != nil
            {
                changes.serverChangeToken = serverToken
            }
        }
        
        recordZoneFetchCompletionBlock =
        {
            zoneID, serverToken, clientToken, _, error in

            guard zoneID == fetchZoneID else
            {
                log(error: "Unexpected zone: \(zoneID.zoneName)")
                return
            }
            
            if let error = error
            {
                log(error: error.localizedDescription)
                return
            }
            
            if clientToken != nil
            {
                changes.clientChangeToken = clientToken
            }
            
            if serverToken != nil
            {
                changes.serverChangeToken = serverToken
            }
        }
        
        fetchRecordZoneChangesCompletionBlock =
        {
            if let error = $0
            {
                log(error: error.localizedDescription)
                handleResult(nil)
                return
            }
            
            handleResult(changes)
        }
    }
    
    struct Result
    {
        var changedRecords = [CKRecord]()
        var idsOfDeletedRecords = [CKRecord.ID]()
        var serverChangeToken: CKServerChangeToken? = nil
        var clientChangeToken: Data? = nil
    }
}

typealias ChangeFetch = CKFetchRecordZoneChangesOperation

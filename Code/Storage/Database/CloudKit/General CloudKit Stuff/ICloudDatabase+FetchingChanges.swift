import CloudKit
import SwiftObserver
import SwiftyToolz
import PromiseKit

extension ICloudDatabase
{
    // MARK: - Fetch Changes
    
    func fetchChanges(fromZone zoneID: CKRecordZone.ID) -> Promise<ChangeFetchResult>
    {
        return Promise
        {
            resolver in
            
            let fetch = CKFetchRecordZoneChangesOperation(zoneID: zoneID,
                                                          token: serverChangeToken)
            {
                result, error in
                
                if let error = error
                {
                    log(error: error.localizedDescription)
                }
                
                self.serverChangeToken = result?.serverChangeToken
                
                resolver.resolve(result, error)
            }
            
            perform(fetch)
        }
    }
    
    // MARK: - Server Change Token
    
    private var serverChangeToken: CKServerChangeToken?
    {
        get
        {
            let defaults = UserDefaults.standard
            
            guard let tokenData = defaults.data(forKey: tokenKey) else
            {
                return nil
            }
            
            let token = NSKeyedUnarchiver.unarchiveObject(with: tokenData)
            
            return token as? CKServerChangeToken
        }
        
        set
        {
            let defaults = UserDefaults.standard
            
            guard let newToken = newValue else
            {
                defaults.removeObject(forKey: tokenKey)
                return
            }
            
            let tokenData = NSKeyedArchiver.archivedData(withRootObject: newToken)
            
            defaults.set(tokenData, forKey: tokenKey)
        }
    }
    
    private var tokenKey: String
    {
        return "UserDefaultsKeyItemZoneLastServerChangeToken"
    }
}

private extension CKFetchRecordZoneChangesOperation
{
    convenience init(zoneID fetchZoneID: CKRecordZone.ID,
                     token: CKServerChangeToken?,
                     handleResult: @escaping (ChangeFetchResult?, Error?) -> Void)
    {
        let zoneOptions = CKFetchRecordZoneChangesOperation.ZoneOptions()
        
        zoneOptions.previousServerChangeToken = token
        
        let options = [fetchZoneID : zoneOptions]

        self.init(recordZoneIDs: [fetchZoneID],
                  optionsByRecordZoneID: options)
        
        var result = ChangeFetchResult()
        
        recordChangedBlock =
        {
            record in result.changedCKRecords.append(record)
        }
        
        recordWithIDWasDeletedBlock =
        {
            id, _ in result.idsOfDeletedCKRecords.append(id)
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
                result.clientChangeToken = clientToken
            }
            
            if serverToken != nil
            {
                print("saving change token from ZONE CHANGE TOKENS UPDATED in result:\n\(serverToken?.description)")
                result.serverChangeToken = serverToken
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
                result.clientChangeToken = clientToken
            }
            
            if serverToken != nil
            {
                print("saving change token from ZONE fetch in result:\n\(serverToken?.description)")
                result.serverChangeToken = serverToken
            }
        }
        
        fetchRecordZoneChangesCompletionBlock =
        {
            if let error = $0?.storageError
            {
                log(error: error.message)
                handleResult(nil, error)
                return
            }
            
            handleResult(result, nil)
        }
    }
}

struct ChangeFetchResult
{
    var changedCKRecords = [CKRecord]()
    var idsOfDeletedCKRecords = [CKRecord.ID]()
    var serverChangeToken: CKServerChangeToken? = nil
    var clientChangeToken: Data? = nil
}

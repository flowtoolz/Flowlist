import CloudKit
import FoundationToolz
import SwiftObserver

extension ItemICloudDatabase
{
    func fetchChanges(processChanges: @escaping ChangeProcessor)
    {
        let itemZoneID = CKRecordZone.ID.item
        
        let itemZoneOptions = CKFetchRecordZoneChangesOperation.ZoneOptions()
        
        print("token: \(serverChangeToken?.debugDescription ?? "nil")")
        
        itemZoneOptions.previousServerChangeToken = serverChangeToken
        
        let options = [itemZoneID : itemZoneOptions]

        let operation = FetchChangesOperation(recordZoneIDs: [itemZoneID],
                                              optionsByRecordZoneID: options)
        
        var changedRecords = [CKRecord]()
        
        operation.recordChangedBlock =
        {
            record in changedRecords.append(record)
        }
        
        var deletionIDs = [CKRecord.ID]()
        
        operation.recordWithIDWasDeletedBlock =
        {
            id, _ in deletionIDs.append(id)
        }
        
        operation.recordZoneChangeTokensUpdatedBlock =
        {
            zoneID, newToken, _ in
            
            print("recordZoneChangeTokensUpdatedBlock")
            print("new token: \(newToken?.debugDescription ?? "nil")")
            
            guard zoneID == itemZoneID else
            {
                log(error: "Unexpected zone: \(zoneID.zoneName)")
                return
            }
            
            self.serverChangeToken = newToken
        }
        
        operation.recordZoneFetchCompletionBlock =
        {
            zoneID, token, _, moreIsComing, error in
            
            print("recordZoneFetchCompletionBlock")
            print("new token: \(token?.debugDescription ?? "nil")")
            
            guard zoneID == itemZoneID else
            {
                log(error: "Unexpected zone: \(zoneID.zoneName)")
                return
            }
            
            if let error = error
            {
                log(error: error.localizedDescription)
                return
            }
            
            self.serverChangeToken = token
        }
        
        operation.fetchRecordZoneChangesCompletionBlock =
        {
            print("fetchRecordZoneChangesCompletionBlock")
            
            if let error = $0
            {
                log(error: error.localizedDescription)
                processChanges(nil, nil)
                return
            }
            
            processChanges(changedRecords, deletionIDs)
            
            changedRecords.removeAll()
            deletionIDs.removeAll()
        }
        
        database.add(operation)
    }
    
    typealias ChangeProcessor = (_ changedRecords: [CKRecord]?,
                                 _ deletedIDs: [CKRecord.ID]?) -> Void
    
    private typealias FetchChangesOperation = CKFetchRecordZoneChangesOperation
    
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

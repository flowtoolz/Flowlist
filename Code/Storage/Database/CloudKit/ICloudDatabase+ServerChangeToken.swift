import CloudKit
import SwiftObserver

extension ICloudDatabase
{
    // MARK: - Fetch & Update Token
    
    func updateServerChangeToken(zoneID: CKRecordZone.ID,
                                 oldToken: CKServerChangeToken?,
                                 handleResult: @escaping (ChangeFetch.Result?) -> Void)
    {
        let fetch = ChangeFetch(zoneID: zoneID, token: oldToken)
        {
            result in
            
            self.serverChangeToken = result?.serverChangeToken
            
            handleResult(result)
        }
        
        database.add(fetch)
    }
    
    // MARK: - Server Change Token
    
    private(set) var serverChangeToken: CKServerChangeToken?
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

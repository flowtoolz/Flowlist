import CloudKit
import SwiftObserver
import PromiseKit

extension ICloudDatabase
{
    // MARK: - Fetch & Update Token
    
    func updateServerChangeToken(zoneID: CKRecordZone.ID,
                                 oldToken: CKServerChangeToken?) -> Promise<ChangeFetch.Result>
    {
        return Promise { resolver in
            let fetch = ChangeFetch(zoneID: zoneID, token: oldToken)
            {
                result, error in
                
                self.serverChangeToken = result?.serverChangeToken
                
                resolver.resolve(result, error)
            }
            
            self.database.add(fetch)
        }
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

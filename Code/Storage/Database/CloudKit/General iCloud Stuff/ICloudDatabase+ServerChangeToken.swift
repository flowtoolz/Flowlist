import CloudKit
import SwiftObserver
import SwiftyToolz
import PromiseKit

extension ICloudDatabase
{
    // MARK: - Fetch Changes and Save New Token
    
    func fetchChanges(fromZone zoneID: CKRecordZone.ID,
                      oldToken: CKServerChangeToken?) -> Promise<ChangeFetch.Result>
    {
        return Promise
        {
            resolver in
            
            let fetch = ChangeFetch(zoneID: zoneID, token: oldToken)
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

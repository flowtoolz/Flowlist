import Foundation

var isFullVersion: Bool
{
    get
    {
        return UserDefaults.standard.string(forKey: userNameKey) != nil
    }
    
    set
    {
        if newValue
        {
            UserDefaults.standard.set(NSFullUserName(), forKey: userNameKey)
        }
        else
        {
            UserDefaults.standard.removeObject(forKey: userNameKey)
        }
    }
}

fileprivate let userNameKey = "UserName"

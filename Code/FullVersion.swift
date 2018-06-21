import Foundation

var reachedTaskNumberLimit: Bool
{
    #if RELEASE
    return !isFullVersion && Task.numberOfTasks >= maxNumberOfTasksInTrial
    #else
    return false
    #endif
}

var isFullVersion: Bool
{
    get
    {
        if let fullVersion = isFullVersion_Cached { return fullVersion }
        
        let fullVersion = UserDefaults.standard.string(forKey: userNameKey) != nil
        
        isFullVersion_Cached = fullVersion
        
        return fullVersion
    }
    
    set
    {
        isFullVersion_Cached = newValue
        
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

fileprivate var isFullVersion_Cached: Bool?
fileprivate let maxNumberOfTasksInTrial = 100
fileprivate let userNameKey = "UserName"

import Foundation

var reachedTaskNumberLimit: Bool
{
    let userCreatedTasks = numberOfUserCreatedTasks.latestUpdate
    
    return !isFullVersion && userCreatedTasks >= maxNumberOfTasksInTrial
}

var isFullVersion: Bool
{
    get
    {
        #if BETA
        return true
        #endif
        
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

let numberOfUserCreatedTasks = store.numberOfUserCreatedLeafs.new().unwrap(0)

fileprivate var isFullVersion_Cached: Bool?
fileprivate let maxNumberOfTasksInTrial = 100
fileprivate let userNameKey = "UserName"

import Foundation

var reachedItemNumberLimit: Bool
{
    let userCreatedLeafs = numberOfUserCreatedLeafs.latestUpdate
    
    return !isFullVersion && userCreatedLeafs >= maxNumberOfLeafsInTrial
}

var isFullVersion: Bool
{
    get
    {
        #if BETA
        
        return true
        
//        #elseif DEBUG
//        
//        return true
        
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

let numberOfUserCreatedLeafs = Store.shared.numberOfUserCreatedLeafs.new().unwrap(0)
let maxNumberOfLeafsInTrial = 100

fileprivate var isFullVersion_Cached: Bool?
fileprivate let userNameKey = "UserName"

var fullVersionPrice: NSDecimalNumber?
var fullVersionPriceLocale: Locale?
var fullVersionFormattedPrice: String?

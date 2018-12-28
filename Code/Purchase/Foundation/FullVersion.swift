import Foundation

// TODO: extract model code from this file / avoid Foundation dependence

// MARK: - Item Limit

var reachedItemNumberLimit: Bool
{
    let userCreatedLeafs = numberOfUserCreatedLeafs.latestMessage
    
    return !isFullVersion && userCreatedLeafs >= maxNumberOfLeafsInTrial
}

let numberOfUserCreatedLeafs = Store.shared.numberOfUserCreatedLeafs.new()
let maxNumberOfLeafsInTrial = 100

// MARK: - Price

var fullVersionPrice: NSDecimalNumber?
var fullVersionPriceLocale: Locale?
var fullVersionFormattedPrice: String?

// MARK: - Persistent Full Version Flag

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
        
        let fullVersion = persister.string(userNameKey) != nil
        
        isFullVersion_Cached = fullVersion
        
        return fullVersion
    }
    
    set
    {
        isFullVersion_Cached = newValue
        
        persister.set(userNameKey, newValue ? NSFullUserName() : nil)
    }
}

fileprivate var isFullVersion_Cached: Bool?
fileprivate let userNameKey = "UserName"

import Foundation

// TODO: extract model code from this file / avoid Foundation dependence

// MARK: - Item Limit

var reachedItemNumberLimit: Bool
{
    let userCreatedLeafs = TreeSelector.shared.numberOfUserCreatedLeafs.value
    
    return !isFullVersion && userCreatedLeafs >= maxNumberOfLeafsInTrial
}

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
        
        #elseif DEBUG

        return false
        
        #else
        
        if let fullVersion = isFullVersion_Cached { return fullVersion }
        
        let fullVersion = Persistent.string[userNameKey] != nil
        
        isFullVersion_Cached = fullVersion
        
        return fullVersion
        
        #endif
    }
    
    set
    {
        isFullVersion_Cached = newValue
        
        Persistent.string[userNameKey] = newValue ? NSFullUserName() : nil
    }
}

private var isFullVersion_Cached: Bool?
private let userNameKey = "UserName"

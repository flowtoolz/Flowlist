import Foundation

class UserDefaultsFlags: PersistentFlags
{
    func get(_ key: String) -> Bool
    {
        return UserDefaults.standard.bool(forKey: key)
    }
    
    func set(_ key: String, _ value: Bool)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
}

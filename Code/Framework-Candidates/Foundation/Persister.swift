import Foundation

class Persister: PersisterInterface
{
    func bool(_ key: String) -> Bool
    {
        return UserDefaults.standard.bool(forKey: key)
    }
    
    func set(_ key: String, _ value: Bool)
    {
        UserDefaults.standard.set(value, forKey: key)
    }
    
    func string(_ key: String) -> String?
    {
        return UserDefaults.standard.string(forKey: key)
    }
    
    func set(_ key: String, _ value: String?)
    {
        if let value = value
        {
            UserDefaults.standard.set(value, forKey: key)
        }
        else
        {
            UserDefaults.standard.removeObject(forKey: key)
        }
    }
}

import Foundation

class Persister: PersisterInterface
{
    func bool(_ key: String) -> Bool?
    {
        return UserDefaults.standard.object(forKey: key) as? Bool
    }
    
    func set(_ key: String, _ value: Bool?)
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

import Foundation

extension Persistent
{
    static func setupUsingUserDefaults()
    {
        bool = UDBoolPersister()
        string = UDStringPersister()
    }
}

class UDBoolPersister: BoolPersisterInterface
{
    subscript(_ key: String) -> Bool?
    {
        get
        {
            return UserDefaults.standard.object(forKey: key) as? Bool
        }
        
        set
        {
            if let value = newValue
            {
                UserDefaults.standard.set(value, forKey: key)
            }
            else
            {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

class UDStringPersister: StringPersisterInterface
{
    subscript(_ key: String) -> String?
    {
        get
        {
            return UserDefaults.standard.string(forKey: key)
        }
        
        set
        {
            if let value = newValue
            {
                UserDefaults.standard.set(value, forKey: key)
            }
            else
            {
                UserDefaults.standard.removeObject(forKey: key)
            }
        }
    }
}

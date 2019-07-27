import Foundation

struct PersistentString
{
    init(_ key: String, default: String = "")
    {
        self.key = key
        self.default = `default`
    }
    
    public var value: String
    {
        get { return Persistent.string[key] ?? `default` }
        set { Persistent.string[key] = newValue }
    }
    
    func erase()
    {
        Persistent.string[key] = nil
    }
    
    let key: String
    let `default`: String
}

struct PersistentFlag
{
    init(_ key: String, default: Bool = false)
    {
        self.key = key
        self.default = `default`
    }
    
    public var value: Bool
    {
        get { return Persistent.bool[key] ?? `default` }
        set { Persistent.bool[key] = newValue }
    }
    
    func erase()
    {
        Persistent.bool[key] = nil
    }
    
    let key: String
    let `default`: Bool
}

struct Persistent
{
    static var bool = UserDefaultsBool()
    static var string = UserDefaultsString()
}

struct UserDefaultsBool
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

struct UserDefaultsString
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

public struct PersistentFlag
{
    init(_ key: String, default: Bool = false)
    {
        self.key = key
        self.default = `default`
    }
    
    public var value: Bool
    {
        get { return persister.bool(key) ?? `default` }
        set { persister.set(key, newValue)}
    }
    
    func erase()
    {
        let nilBool: Bool? = nil
        persister.set(key, nilBool)
    }
    
    let key: String
    let `default`: Bool
}

public var persister: PersisterInterface = DummyPersister()

fileprivate class DummyPersister: PersisterInterface
{
    func string(_ key: String) -> String? { fatalError(error) }
    func set(_ key: String, _ value: String?) { fatalError(error) }
    func bool(_ key: String) -> Bool? { fatalError(error) }
    func set(_ key: String, _ value: Bool?) { fatalError(error) }
    
    let error = "No Persister implementation has been provided."
}

public protocol PersisterInterface: class
{
    func bool(_ key: String) -> Bool?
    func set(_ key: String, _ value: Bool?)
    
    func string(_ key: String) -> String?
    func set(_ key: String, _ value: String?)
}

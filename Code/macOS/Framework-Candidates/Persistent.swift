// TODO: do this with property wrappers when we migrate to Swift 5.1 ... also add PersistentInt or make this generic somehow

public struct PersistentString
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

public struct PersistentFlag
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

// MARK: - Persistent Values

public struct Persistent
{
    private init() {}
    
    static var bool: BoolPersisterInterface = DummyBoolPersister()
    static var string: StringPersisterInterface = DummyStringPersister()
}

// MARK: - Private Dummy Implementations

private class DummyBoolPersister: BoolPersisterInterface
{
    subscript(_ key: String) -> Bool?
    {
        get { fatalError(error) }
        set { fatalError(error) }
    }
}

private class DummyStringPersister: StringPersisterInterface
{
    subscript(_ key: String) -> String?
    {
        get { fatalError(error) }
        set { fatalError(error) }
    }
}

private let error = "No Persister implementation has been provided."

// MARK: - Public Interfaces

public protocol BoolPersisterInterface: class
{
    subscript(_ key: String) -> Bool? { get set }
}

public protocol StringPersisterInterface: class
{
    subscript(_ key: String) -> String? { get set }
}



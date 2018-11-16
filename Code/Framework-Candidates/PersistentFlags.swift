public var persistentFlags: PersistentFlags = DummyPersistentFlags()

fileprivate class DummyPersistentFlags: PersistentFlags
{
    func get(_ key: String) -> Bool
    {
        fatalError("No PersistentFlags implementation has been provided.")
    }
    
    func set(_ key: String, _ value: Bool)
    {
        fatalError("No PersistentFlags implementation has been provided.")
    }
}

public protocol PersistentFlags: class
{
    func get(_ key: String) -> Bool
    func set(_ key: String, _ value: Bool)
}

public extension KeyedDecodingContainer
{
    func int(_ key: Key) -> Int?
    {
        try? decode(Int.self, forKey: key)
    }
    
    func string(_ key: Key) -> String?
    {
        try? decode(String.self, forKey: key)
    }
    
    func get<T>(_ type: T.Type, for key: Key) -> T? where T : Decodable
    {
        try? decode(type, forKey: key)
    }
}

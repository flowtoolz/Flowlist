public extension KeyedDecodingContainer
{
    func int(_ key: Key) -> Int?
    {
        return try? decode(Int.self, forKey: key)
    }
    
    func string(_ key: Key) -> String?
    {
        return try? decode(String.self, forKey: key)
    }
    
    func get<T>(_ type: T.Type,
                for key: KeyedDecodingContainer<K>.Key) -> T? where T : Decodable
    {
        return try? decode(type, forKey: key)
    }
}

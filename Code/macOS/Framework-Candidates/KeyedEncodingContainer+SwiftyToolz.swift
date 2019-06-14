public extension KeyedEncodingContainer
{
    mutating func set(_ value: String?, for key: Key)
    {
        guard let value = value else { return }
        
        try? encode(value, forKey: key)
    }
    
    mutating func set(_ value: Int?, for key: Key)
    {
        guard let value = value else { return }
        
        try? encode(value, forKey: key)
    }
    
    mutating func set<T>(_ value: T?, for key: Key) where T : Encodable
    {
        guard let value = value else { return }
        
        try? encode(value, forKey: key)
    }
}

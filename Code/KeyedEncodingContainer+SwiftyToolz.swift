public extension KeyedEncodingContainer
{
    mutating func set(_ value: String?, for key: KeyedEncodingContainer<K>.Key)
    {
        guard let value = value else { return }
        
        try? encode(value, forKey: key)
    }
    
    mutating func set(_ value: Int?, for key: KeyedEncodingContainer<K>.Key)
    {
        guard let value = value else { return }
        
        try? encode(value, forKey: key)
    }
    
    mutating func set<T>(_ value: T?,
                         for key: KeyedEncodingContainer<K>.Key) where T : Encodable
    {
        guard let value = value else { return }
        
        try? encode(value, forKey: key)
    }
}

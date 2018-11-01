extension Tree: Encodable where Data == ItemData
{
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: JsonKey.self)
        
        container.set(data.id, for: .id)
        container.set(text, for: .text)
        container.set(data.state.value?.rawValue, for: .state)
        container.set(data.tag.value?.rawValue, for: .tag)
        
        if !isLeaf
        {
            container.set(branches, for: .subitems)
        }
    }
    
    enum JsonKey: String, CodingKey
    {
        case id, text = "title", state, tag, subitems = "subtasks"
    }
}

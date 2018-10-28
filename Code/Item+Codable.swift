import SwiftObserver

extension Tree: Codable where Data == ItemData
{
    convenience init(from decoder: Decoder) throws
    {
        self.init(data: nil)
        
        guard let container = try? decoder.container(keyedBy: CodingKeys.self) else
        {
            return
        }
        
        let id = try? container.decode(String.self, forKey: .id)
        
        data = ItemData(id: id)
        
        if let text = try? container.decode(String.self, forKey: .text)
        {
            data?.text <- text
        }
        else if let textVar = try? container.decode(Var<String>.self,
                                                    forKey: .text)
        {
            data?.text = textVar
        }
        
        if let integer = try? container.decode(Int.self, forKey: .state)
        {
            data?.state <- ItemData.State(rawValue: integer)
        }
        else if let stateVar = try? container.decode(Var<ItemData.State>.self,
                                                     forKey: .state)
        {
            data?.state = stateVar
        }
        
        if let integer = try? container.decode(Int.self, forKey: .tag)
        {
            data?.tag <- ItemData.Tag(rawValue: integer)
        }
        else if let tagVar = try? container.decode(Var<ItemData.Tag>.self,
                                                   forKey: .tag)
        {
            data?.tag = tagVar
        }
        
        if let branches = try? container.decode([Node].self, forKey: .branches)
        {
            reset(branches: branches)
        }
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        if let id = data?.id
        {
            try? container.encode(id, forKey: .id)
        }
        
        if let text = text
        {
            try? container.encode(text, forKey: .text)
        }
        
        if let stateInteger = data?.state.value?.rawValue
        {
            try? container.encode(stateInteger, forKey: .state)
        }
        
        if let tagInteger = data?.tag.value?.rawValue
        {
            try? container.encode(tagInteger, forKey: .tag)
        }
        
        if !isLeaf
        {
            try? container.encode(branches, forKey: CodingKeys.branches)
        }
    }
    
    enum CodingKeys: String, CodingKey
    {
        case id, text = "title", state, tag, branches = "subtasks"
    }
}

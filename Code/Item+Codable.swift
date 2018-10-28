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
        
        if let titleString = try? container.decode(String.self, forKey: .title)
        {
            data?.title <- titleString
        }
        else if let title = try? container.decode(Var<String>.self, forKey: .title)
        {
            data?.title = title
        }
        
        if let integer = try? container.decode(Int.self, forKey: .state)
        {
            data?.state <- ItemData.State(rawValue: integer)
        }
        else if let state = try? container.decode(Var<ItemData.State>.self,
                                                  forKey: .state)
        {
            data?.state = state
        }
        
        if let integer = try? container.decode(Int.self, forKey: .tag)
        {
            data?.tag <- ItemData.Tag(rawValue: integer)
        }
        else if let tag = try? container.decode(Var<ItemData.Tag>.self, forKey: .tag)
        {
            data?.tag = tag
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
        
        if let titleString = title
        {
            try? container.encode(titleString, forKey: .title)
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
        case id, title, state, tag, branches = "subtasks"
    }
}

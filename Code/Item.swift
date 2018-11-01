import SwiftObserver

class Item: Tree<ItemData>, Codable
{
    required convenience init(from decoder: Decoder) throws
    {
        self.init(data: nil)
        
        guard let container = decoder.itemContainer else { return }
        
        data = container.itemData
        
        reset(branches: container.get([Item].self, for: .branches))
    }
    
    func encode(to encoder: Encoder) throws
    {
        var container = encoder.container(keyedBy: ItemCodingKey.self)
        
        container.set(data?.id, for: .id)
        container.set(text, for: .text)
        container.set(data?.state.value?.rawValue, for: .state)
        container.set(data?.tag.value?.rawValue, for: .tag)
        
        if !isLeaf
        {
            let subitems: [Item] = branches.map { Item(from: $0) }
            
            container.set(subitems, for: .branches)
        }
    }
    
    convenience init(from itemDataTree: ItemDataTree)
    {
        self.init(data: itemDataTree.data,
                  root: itemDataTree.root,
                  numberOfLeafs: itemDataTree.numberOfLeafs)
        
        reset(branches: itemDataTree.branches)
    }
}

// MARK: - Codability

fileprivate extension Decoder
{
    var itemContainer: KeyedDecodingContainer<ItemCodingKey>?
    {
        return try? container(keyedBy: ItemCodingKey.self)
    }
}

fileprivate extension KeyedDecodingContainer where K == ItemCodingKey
{
    var itemData: ItemData
    {
        let data = ItemData(id: id)
        
        data.text <- text
        data.state <- state
        data.tag <- tag
        
        return data
    }
    
    var id: String? { return string(.id) }
    
    var text: String?
    {
        return string(.text) ?? get(Var<String>.self, for: .text)?.value
    }
    
    var state: ItemData.State?
    {
        let direct = ItemData.State(from: int(.state))
        return direct ?? get(Var<ItemData.State>.self, for: .state)?.value
    }
    
    var tag: ItemData.Tag?
    {
        let direct = ItemData.Tag(from: int(.tag))
        return direct ?? get(Var<ItemData.Tag>.self, for: .tag)?.value
    }
}

fileprivate enum ItemCodingKey: String, CodingKey
{
    case id, text = "title", state, tag, branches = "subtasks"
}

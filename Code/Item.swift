import SwiftObserver

class Item: Tree<ItemData>, Decodable, Observable
{
    // MARK: - Decodable
    
    required convenience init(from decoder: Decoder) throws
    {
        self.init(data: nil)
        
        guard let container = decoder.itemContainer else { return }
        
        data = container.itemData
        
        if let branches = container.get([Item].self, for: .branches)
        {
            reset(branches: branches)
        }
    }
    
    override init(data: ItemData?,
                  root: Node? = nil,
                  numberOfLeafs: Int = 1)
    {
        super.init(data: data,
                   root: root,
                   numberOfLeafs: numberOfLeafs)
    }
    
    // MARK: - Observable
    
    var latestUpdate = Event.didNothing
    
    enum Event { case didNothing }
}

// MARK: - Decoding

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

// MARK: - Item Coding Key

enum ItemCodingKey: String, CodingKey
{
    case id, text = "title", state, tag, branches = "subtasks"
}

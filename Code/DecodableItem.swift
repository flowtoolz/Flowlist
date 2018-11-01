import SwiftObserver
import SwiftyToolz

class DecodableItem: Tree<ItemData>, Decodable
{
    required convenience init(from decoder: Decoder) throws
    {
        let container = try decoder.itemContainer()
        
        self.init(data: container.itemData)
        
        if let branches = container.get([DecodableItem].self, for: .subitems)
        {
            for subitem in branches { subitem.root = self }
            
            reset(branches: branches)
        }
    }
}

// MARK: - Decoding

fileprivate extension Decoder
{
    func itemContainer() throws -> KeyedDecodingContainer<Item.JsonKey>
    {
        return try container(keyedBy: Item.JsonKey.self)
    }
}

fileprivate extension KeyedDecodingContainer where K == Item.JsonKey
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

import SwiftObserver

typealias PersistableStore = Persistable & StoreInterface

extension Store: StoreInterface
{
    func updateItem(with edit: ItemEdit)
    {
        // TODO: be aware that, on modification, icloud always sends root and text, even if they weren't modified
        
        switch edit
        {
        case .didNothing: break
            
        case .didCreate(let info):
            let newItem = Item(data: info.data)
            
            itemHash.add([newItem])
            
            if let rootId = info.rootId,
                let rootItem = itemHash[rootId]
            {
                rootItem.add(newItem)
            }
            
        case .didModify(let info):
            let id = info.data.id
            
            guard let item = itemHash[id] else { break }
            
            for field in info.modified
            {
                switch field
                {
                case .text:
                    item.data?.text <- info.data.text.value
                    
                case .state:
                    item.data?.state <- info.data.state.value
                    
                case .tag:
                    item.data?.tag <- info.data.tag.value
                    
                case .root: break
                }
            }
            
        case .didDelete(let id): removeItem(with: id)
        }
    }
    
    private func removeItem(with id: String)
    {
        guard let item = itemHash[id] else { return }
        
        itemHash.remove([item])
        
        guard let superItem = item.root,
            let index = item.indexInRoot else { return }
        
        superItem.removeNodes(from: [index])
    }
}

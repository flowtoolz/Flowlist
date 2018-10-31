import SwiftObserver

extension Store: StoreInterface
{
    func apply(_ itemEdit: Item.Edit)
    {
        switch itemEdit
        {
        case .didNothing: break
        case .didCreate(let info): createItem(with: info)
        case .didModify(let info): updateItem(with: info)
        case .didDelete(let id): removeItem(with: id)
        }
    }
    
    private func createItem(with info: ItemEditInfo)
    {
        let newItem = Item(data: ItemData(from: info))
        
        itemHash.add([newItem])
        
        guard let rootId = info.rootId else
        {
            log(warning: "New item (id \(info.id)) has no root.")
            return
        }
        
        guard let rootItem = itemHash[rootId] else
        {
            log(warning: "Root (id \(rootId)) of new item (id \(info.id)) is not in hash map.")
            return
        }
        
        rootItem.add(newItem)
    }
    
    private func updateItem(with info: ItemEditInfo)
    {
        guard let item = itemHash[info.id] else
        {
            log(error: "Item with id \(info.id) is not in hash map.")
            return
        }
        
        // TODO: updating an Item with ItemEditInfo should be an Item extension
        for field in info.modified
        {
            switch field
            {
            case .text: item.data?.text <- info.text
            case .state: item.data?.state <- info.state
            case .tag: item.data?.tag <- info.tag
            case .root: log(error: "Did not expect direct modification of item root. ID: \(info.id). Intended new root ID: \(String(describing: info.rootId)) item Text: \(item.text ?? "nil")")
            }
        }
    }
    
    private func removeItem(with id: String)
    {
        guard let item = itemHash[id] else
        {
            log(error: "Item with id \(id) is not in hash map.")
            return
        }
        
        itemHash.remove([item])
        
        guard let superItem = item.root,
            let index = item.indexInRoot
        else
        {
            log(warning: "Did remove root with id \(id) from hash map. Text: \(item.text ?? "nil")")
            return
        }
        
        superItem.removeNodes(from: [index])
    }
}

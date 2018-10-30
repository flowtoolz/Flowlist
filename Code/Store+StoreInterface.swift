import SwiftObserver

extension Store: StoreInterface
{
    func apply(_ itemEdit: ItemEdit)
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
        let newItem = Item(data: info.data)
        
        itemHash.add([newItem])
        
        guard let rootId = info.rootId else
        {
            log(warning: "New item (id \(info.data.id)) has no root.")
            return
        }
        
        guard let rootItem = itemHash[rootId] else
        {
            log(warning: "Root (id \(rootId)) of new item (id \(info.data.id)) is no in hash map.")
            return
        }
        
        rootItem.add(newItem)
    }
    
    private func updateItem(with info: ItemEditInfo)
    {
        guard let item = itemHash[info.data.id] else
        {
            log(error: "Item with id \(info.data.id) is not in hash map.")
            return
        }
        
        for field in info.modified
        {
            switch field
            {
            case .text: item.data?.text <- info.data.text.value
            case .state: item.data?.state <- info.data.state.value
            case .tag: item.data?.tag <- info.data.tag.value
            case .root:
                // TODO: implement this to be safe
                break
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

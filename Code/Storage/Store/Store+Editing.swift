import SwiftObserver

extension Store
{
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .insertItem(let modifications, _):
            for modification in modifications
            {
                createItem(with: modification)
            }
        case .modifyItem(let modification):
            updateItem(with: modification)
        case .removeItemsWithIds(let nodeIds):
            for id in nodeIds
            {
                if itemHash[id] != nil
                {
                    removeItem(with: id)
                }
            }
        }
    }
    
    private func createItem(with modification: Modification)
    {
        let newItem = Item(from: modification)
        
        itemHash.add([newItem])
        
        guard let rootId = modification.rootId else
        {
            log(warning: "New item (id \(modification.id)) has no root.")
            return
        }
        
        guard let rootItem = itemHash[rootId] else
        {
            log(warning: "Root (id \(rootId)) of new item (id \(modification.id)) is not in hash map.")
            return
        }
        
        rootItem.add(newItem)
    }
    
    private func updateItem(with modification: Modification)
    {
        guard let item = itemHash[modification.id] else
        {
            log(error: "Item with id \(modification.id) is not in hash map.")
            return
        }
        
        // TODO: updating an Item should be an Item extension
        for field in modification.modified
        {
            switch field
            {
            case .text: item.data.text <- modification.text
            case .state: item.data.state <- modification.state
            case .tag: item.data.tag <- modification.tag
            case .root: log(error: "Did not expect direct modification of item root. ID: \(modification.id). Intended new root ID: \(String(describing: modification.rootId)) item Text: \(item.text ?? "nil")")
            case .position:
                guard let newPosition = modification.position,
                    let itemRoot = item.root,
                    let oldPosition = itemRoot.index(of: item),
                    oldPosition != newPosition
                else
                {
                    break
                }
                
                itemRoot.moveNode(from: oldPosition, to: newPosition)
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
        
        itemHash.remove(item.array)
        
        guard let superItem = item.root, let index = item.indexInRoot else
        {
            log(warning: "Did remove root with id \(id) from hash map. Text: \(item.text ?? "nil")")
            return
        }

        superItem.removeNodes(from: [index])
    }
}

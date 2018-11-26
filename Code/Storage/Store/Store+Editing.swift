import SwiftObserver

extension Store
{
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .updateItems(let modifications):
            updateItems(with: modifications)
            
        case .removeItems(let nodeIds):
            for id in nodeIds
            {
                if itemHash[id] != nil
                {
                    removeItem(with: id)
                }
            }
        }
    }
    
    private func updateItems(with modifications: [Modification])
    {
        // ensure items are in hash map and have updated data
        
        for mod in modifications
        {
            if let item = itemHash[mod.id]
            {
                item.data.text <- mod.text
                item.data.state <- mod.state
                item.data.tag <- mod.tag
            }
            else
            {
                itemHash.add([Item(modification: mod)])
            }
        }
        
        // connect items
        
        for mod in modifications.sorted(by: { $0.position < $1.position })
        {
            guard let item = itemHash[mod.id] else
            {
                log(error: "Item not in hash map.")
                continue
            }
            
            updateRoot(of: item, with: mod)
        }
    }
    
    private func updateRoot(of item: Item, with modification: Modification)
    {
        // move to new root if neccessary
        
        // TODO: catch errors...nil root etc
        if let oldRoot = item.root,
            let oldIndex = oldRoot.index(of: item),
            let newRootID = modification.rootID,
            newRootID != oldRoot.data.id,
            let newRoot = itemHash[newRootID]
        {
            oldRoot.removeNodes(from: [oldIndex])
            newRoot.insert(item, at: 0)
        }
        
        // move to new position if necessary
        
        if let itemRoot = item.root,
            let oldPosition = itemRoot.index(of: item)
        {
            let newPosition = min(itemRoot.numberOfLeafs,
                                  modification.position)
            
            if oldPosition != newPosition
            {
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

import SwiftObserver

extension Store
{
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .insertItems(let modifications, let rootID):
            let sortedByPosition = modifications.sorted
            {
                $0.position ?? 0 < $1.position ?? 0
            }
            
            for modification in sortedByPosition
            {
                createItem(with: modification, inItemWithID: rootID)
            }
        case .modifyItem(let modification, let rootID):
            updateItem(with: modification, rootID: rootID)
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
    
    private func createItem(with modification: Modification,
                            inItemWithID rootID: String?)
    {
        guard let rootId = rootID else
        {
            log(error: "Trying to create new root. This is unhandled.")
            return
        }
        
        guard let rootItem = itemHash[rootId] else
        {
            log(warning: "Root (id \(rootId)) of new item (id \(modification.id)) is not in hash map.")
            return
        }
        
        let newItem = Item(modification: modification)
        
        itemHash.add([newItem])
        
        rootItem.insert(newItem,
                        at: modification.position ?? rootItem.count)
    }
    
    private func updateItem(with modification: Modification, rootID: String?)
    {
        
        // TODO: updating an Item should be an Item extension
        
        guard let item = itemHash[modification.id] else
        {
            log(error: "Item with id \(modification.id) is not in hash map.")
            return
        }
        
        item.data.text <- modification.text
        item.data.state <- modification.state
        item.data.tag <- modification.tag
        
        if item.root?.data.id != rootID
        {
            log(error: "Did not expect direct modification of item root. ID: \(modification.id). Intended new root ID: \(String(describing: rootID)) item Text: \(item.text ?? "nil")")
        }
        
        let newPosition = modification.position
        
        if let itemRoot = item.root,
            let oldPosition = itemRoot.index(of: item)
        {
            if oldPosition != newPosition
            {
                itemRoot.moveNode(from: oldPosition, to: newPosition)
            }
        }
        else
        {
            log(error: "Invalid position: Item is root or modification has no position.")
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

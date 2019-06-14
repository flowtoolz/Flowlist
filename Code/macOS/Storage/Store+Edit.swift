import SwiftObserver
import SwiftyToolz

extension Store
{
    // MARK: - Apply Edits (essentially, edits received from (iCloud-) database)
    
    func apply(_ edit: Edit)
    {
        DispatchQueue.main.async
        {
            switch edit
            {
            case .updateItems(let records): self.updateItems(with: records)
            case .removeItems(let ids): self.removeItems(with: ids)
            }
        }
    }
    
    // MARK: - Update Items
    
    private func updateItems(with updatedRecords: [Record])
    {
        var arrayOfItemRootIDPosition = [(Item, String?, Int)]()
        
        // ensure items are in hash map and have updated data
        
        for updatedRecord in updatedRecords
        {
            if let existingItem = itemHash[updatedRecord.id]
            {
                existingItem.data.text <- updatedRecord.text
                existingItem.data.state <- updatedRecord.state
                existingItem.data.tag <- updatedRecord.tag
                
                arrayOfItemRootIDPosition.append((existingItem,
                                                  updatedRecord.rootID,
                                                  updatedRecord.position))
            }
            else
            {
                let newItem = Item(record: updatedRecord)
                itemHash.add([newItem])
                
                arrayOfItemRootIDPosition.append((newItem,
                                                  updatedRecord.rootID,
                                                  updatedRecord.position))
            }
        }
        
        // connect items
        
        updateItemsWithNewRootAndPosition(arrayOfItemRootIDPosition)
    }
    
    private func updateItemsWithNewRootAndPosition(_ array: [(Item, String?, Int)])
    {
        let sortedByPosition = array.sorted { $0.2 < $1.2 }
        
        for (item, rootID, _) in sortedByPosition
        {
            move(item, toNewRootID: rootID)
        }
        
        for (item, _, position) in sortedByPosition
        {
            move(item, toNewPosition: position)
        }
    }
    
    private func move(_ item: Item, toNewRootID rootID: String?)
    {
        // TODO: catch errors...nil root etc
        if let oldRoot = item.root,
            let oldIndex = oldRoot.index(of: item),
            let newRootID = rootID,
            newRootID != oldRoot.data.id,
            let newRoot = itemHash[newRootID]
        {
            oldRoot.removeNodes(from: [oldIndex])
            newRoot.add(item)
        }
    }
    
    private func move(_ item: Item, toNewPosition position: Int)
    {
        if let itemRoot = item.root,
            let oldPosition = itemRoot.index(of: item)
        {
            let newPosition = min(itemRoot.numberOfLeafs, position)
            
            if oldPosition != newPosition
            {
                itemRoot.moveNode(from: oldPosition, to: newPosition)
            }
        }
    }
    
    // MARK: - Remove Items
    
    private func removeItems(with ids: [String])
    {
        ids.forEach(removeItem)
    }
    
    private func removeItem(with id: String)
    {
        guard let item = itemHash[id] else { return }
        
        guard let superItem = item.root, let index = item.indexInRoot else
        {
            log(error: "Tried to remove root (id \(id)). Text: \(item.text ?? "nil")")
            return
        }
        
        itemHash.remove(item.array)

        superItem.removeNodes(from: [index])
    }
}

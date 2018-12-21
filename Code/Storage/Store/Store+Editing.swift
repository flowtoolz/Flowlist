import SwiftObserver
import SwiftyToolz

extension Store
{
    // MARK: - Apply Edits
    
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
    
    private func updateItems(with records: [Record])
    {
        // ensure items are in hash map and have updated data
        
        for record in records
        {
            if let item = itemHash[record.id]
            {
                item.data.text <- record.text
                item.data.state <- record.state
                item.data.tag <- record.tag
            }
            else
            {
                itemHash.add([Item(record: record)])
            }
        }
        
        // connect items
        
        for record in records.sorted(by: { $0.position < $1.position })
        {
            guard let item = itemHash[record.id] else
            {
                log(error: "Item not in hash map.")
                continue
            }
            
            updateRoot(of: item, with: record)
        }
    }
    
    private func updateRoot(of item: Item, with record: Record)
    {
        // move to new root if neccessary
        
        // TODO: catch errors...nil root etc
        if let oldRoot = item.root,
            let oldIndex = oldRoot.index(of: item),
            let newRootID = record.rootID,
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
                                  record.position)
            
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

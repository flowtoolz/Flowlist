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
        let differingRecs = differingRecords(in: updatedRecords)
        
        guard !differingRecs.isEmpty else { return }
        
        var arrayOfItemRootIDPosition = [(Item, String?, Int)]()
        
        // ensure items are in hash map and have updated data
        
        for differingRecord in differingRecs
        {
            if let existingItem = itemHash[differingRecord.id]
            {
                existingItem.data.text <- differingRecord.text
                existingItem.data.state <- differingRecord.state
                existingItem.data.tag <- differingRecord.tag
                
                arrayOfItemRootIDPosition.append((existingItem,
                                                  differingRecord.rootID,
                                                  differingRecord.position))
            }
            else
            {
                let newItem = differingRecord.makeItem()
                itemHash.add([newItem])
                
                arrayOfItemRootIDPosition.append((newItem,
                                                  differingRecord.rootID,
                                                  differingRecord.position))
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
    
    private func move(_ item: Item, toNewRootID newRootID: String?)
    {
        guard item.root?.data.id != newRootID else { return }
        
        if let oldRoot = item.root, let oldIndex = item.indexInRoot
        {
            oldRoot.removeNodes(from: [oldIndex])
        }
        
        if let newRootID = newRootID
        {
            guard let newRoot = itemHash[newRootID] else
            {
                log(error: "Tried to move item with id \(item.data.id) to non-existing root with id \(newRootID)")
                return
            }
            
            newRoot.add(item)
        }
    }
    
    private func move(_ item: Item, toNewPosition newPosition: Int)
    {
        guard let root = item.root,
            let oldPosition = item.indexInRoot,
            oldPosition != newPosition else { return }
        
        root.moveNode(from: oldPosition,
                      to: min(root.branches.count, newPosition))
    }
    
    // MARK: - Avoid Redundant Edits
    
    func differingRecords(in records: [Record]) -> [Record]
    {
        return records.compactMap
        {
            item(itemHash[$0.id], isEquivalentTo: $0) ? nil : $0
        }
    }
    
    func existingIDs(in ids: [String]) -> [String]
    {
        return ids.compactMap { itemHash[$0]?.data.id }
    }
    
    private func item(_ item: Item?, isEquivalentTo record: Record) -> Bool
    {
        guard let item = item else { return false }
        let itemData = item.data
        if itemData.id != record.id { return false }
        if item.indexInRoot ?? 0 != record.position { return false }
        if itemData.text.value != record.text { return false }
        if itemData.tag.value != record.tag { return false }
        if itemData.state.value != record.state { return false }
        if item.root?.data.id != record.rootID { return false }
        
        return true
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

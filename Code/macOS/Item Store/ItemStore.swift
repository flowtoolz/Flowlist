import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemStore: Observer, CustomObservable
{
    // MARK: - Initialization
    
    static let shared = ItemStore()
    private init() {}
    
    // MARK: - Update Items
    
    func apply(updates: [ItemUpdate])
    {
        DispatchQueue.main.async
        {
            self.updateItemsAssumingMainThread(with: updates)
        }
    }
    
    private func updateItemsAssumingMainThread(with updates: [ItemUpdate])
    {
        guard root != nil else
        {
            if let newRoot = TreeBuilder().buildTree(from: updates)
            {
                update(root: newRoot)
            }
            else
            {
                // TODO: how do we avoid having no root if there's no data coming from icloud?
            }
            
            return
        }
        
        let differences = differingUpdates(in: updates)
        
        guard !differences.isEmpty else { return }
        
        var arrayOfItemRootIDPosition = [(Item, ItemData.ID?, Int)]()
        
        // ensure items are in hash map and have updated data
        
        for difference in differences
        {
            if let existingItem = itemHash[difference.data.id]
            {
                existingItem.data.text <- difference.data.text.value
                existingItem.data.state <- difference.data.state.value
                existingItem.data.tag <- difference.data.tag.value
                
                arrayOfItemRootIDPosition.append((existingItem,
                                                  difference.parentID,
                                                  difference.position))
            }
            else
            {
                let newItem = Item(data: difference.data)
                itemHash.add([newItem])
                
                arrayOfItemRootIDPosition.append((newItem,
                                                  difference.parentID,
                                                  difference.position))
            }
        }
        
        // connect items
        
        updateItemsWithNewRootAndPosition(arrayOfItemRootIDPosition)
    }
    
    private func updateItemsWithNewRootAndPosition(_ array: [(Item, ItemData.ID?, Int)])
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
    
    private func move(_ item: Item, toNewRootID newRootID: ItemData.ID?)
    {
        guard item.parentID != newRootID else { return }
        
        if let oldRoot = item.root, let oldIndex = item.indexInRoot
        {
            oldRoot.removeNodes(from: [oldIndex])
        }
        
        if let newRootID = newRootID
        {
            guard let newRoot = itemHash[newRootID] else
            {
                log(error: "Tried to move item with id \(item.id) to non-existing root with id \(newRootID)")
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
    
    func differingUpdates(in updates: [ItemUpdate]) -> [ItemUpdate]
    {
        return updates.compactMap
        {
            item(itemHash[$0.data.id], isEquivalentTo: $0) ? nil : $0
        }
    }
    
    private func item(_ item: Item?, isEquivalentTo update: ItemUpdate) -> Bool
    {
        guard let item = item else { return false }
        if item.data != update.data { return false }
        if item.id != update.data.id { return false }
        if item.position != update.position { return false }
        if item.parentID != update.parentID { return false }
        
        return true
    }
    
    // MARK: - Delete Items
    
    func deleteItems(withIDs ids: [ItemData.ID])
    {
        DispatchQueue.main.async
        {
            ids.forEach(self.deleteItem)
        }
    }
    
    func deleteItem(withID id: String)
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

    // MARK: - Manage Root
    
    func update(root newRoot: Item)
    {
        stopObserving(root?.treeMessenger)
        observeTreeMessenger(of: newRoot)
        itemHash.reset(with: newRoot.array)
        updateUserCreatedLeafs(with: newRoot)
        
        root = newRoot
    
        DispatchQueue.main.async
        {
            self.send(.didSwitchRoot)
            self.pasteWelcomeTourIfRootIsEmpty()
        }
    }
    
    private func observeTreeMessenger(of newRoot: Item)
    {
        observe(newRoot.treeMessenger)
        {
            [weak self, weak newRoot] event in
            
            guard let newRoot = newRoot else { return }
            
            self?.didReceive(event, from: newRoot)
        }
    }
    
    private func didReceive(_ event: Item.Event, from root: Item)
    {
        switch event
        {
        case .didNothing: break
            
        case .didUpdateNode(let edit):
            if edit.modifiesGraphStructure
            {
                updateUserCreatedLeafs(with: root)
            }
            
        case .didChangeLeafNumber(_):
            updateUserCreatedLeafs(with: root)
            
        case .didUpdateTree(let treeUpdate):
            switch treeUpdate
            {
            case .insertedNodes(let items, _, _):
                var hadAlreadyAddedAll = true
                
                for item in items
                {
                    if itemHash[item.id] == nil
                    {
                        hadAlreadyAddedAll = false
                        itemHash.add(item.array)
                    }
                }
                
                if !hadAlreadyAddedAll
                {
                    send(.didUpdate(treeUpdate))
                }
                
            case .receivedMessage, .movedNode:
                // TODO: avoid sending updates back that were triggered from outside (from database)
                send(.didUpdate(treeUpdate))
                
            case .removedNodes(let items, _):
                var hadAlreadyRemovedAll = true
                
                for item in items
                {
                    if itemHash[item.id] != nil
                    {
                        hadAlreadyRemovedAll = false
                        itemHash.remove(item.array)
                    }
                }
                
                if !hadAlreadyRemovedAll
                {
                    send(.didUpdate(treeUpdate))
                }
            }
        }
    }
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    
    enum Event
    {
        case didSwitchRoot, didUpdate(Item.Event.TreeUpdate)
    }
    
    // MARK: - Welcome Tour
    
    func pasteWelcomeTourIfRootIsEmpty()
    {
        guard let root = self.root else
        {
            log(warning: "Root is nil.")
            return
        }
        
        if root.isLeaf
        {
            root.insert(Item.welcomeTour, at: 0)
        }
    }
    
    // MARK: - Track Number of User Created Leafs
    
    private func updateUserCreatedLeafs(with root: Item)
    {
        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var(0)
    
    // MARK: - Item Storage
    
    private(set) var root: Item?
    private let itemHash = HashMap()
}

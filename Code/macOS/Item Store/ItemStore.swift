import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemStore: Observer, CustomObservable
{
    // MARK: - Initialization
    
    static let shared = ItemStore()
    private init() {}
    
    // MARK: - Update Items
    
    func apply(updates: [Update])
    {
        DispatchQueue.main.async
        {
            self.sortedByPosition(updates).forEach(self.apply)
            
            // TODO: send batch message, not individual messages for each update
        }
    }
    
    private func apply(_ update: Update)
    {
        if let item = itemHash[update.data.id]
        {
            apply(update, to: item)
        }
        else
        {
            createItem(from: update)
        }
    }
    
    private func apply(_ update: Update, to item: Item)
    {
        guard update.wouldChange(item) else { return }
        
        item.data.text <- update.data.text.value
        item.data.state <- update.data.state.value
        item.data.tag <- update.data.tag.value
        
        move(item, toNewTreePositionWith: update)
    }
    
    private func createItem(from update: Update)
    {
        let item = Item(data: update.data)
        itemHash.add([item])
        
        if let lostChildren = orphansByParentID[item.id]
        {
            sortedByPosition(Array(lostChildren.values)).forEach
            {
                guard let child = itemHash[$0.data.id] else { return }
                item.insert(child, at: $0.position)
            }
            
            orphansByParentID[item.id] = nil
        }
        
        if let parentID = update.parentID
        {
            if let parent = itemHash[parentID]
            {
                parent.insert(item, at: update.position)
            }
            else
            {
                updateOrphan(update)
            }
        }
        else
        {
            roots.add([item])
        }
    }
    
    private func move(_ item: Item, toNewTreePositionWith update: Update)
    {
        if item.parentID == nil && update.parentID == nil
        {
            if removeOrphan(withID: item.id) { roots.add([item]) }
            return
        }
        
        if item.parentID == update.parentID
        {
            item.root?.moveNode(from: item.position, to: update.position)
            return
        }
        
        item.root?.removeNodes(from: [item.position])
        
        guard let newParentID = update.parentID else
        {
            roots.add([item])
            return
        }

        roots.remove([item])
        
        if let newParent = itemHash[newParentID]
        {
            newParent.insert(item, at: update.position)
            
            orphansByParentID[newParentID]?[item.id] = nil
        }
        else
        {
            updateOrphan(update)
        }
    }
    
    // MARK: - Delete Items
    
    func deleteItems(withIDs ids: [ItemData.ID])
    {
        DispatchQueue.main.async
        {
            ids.forEach(self.deleteItem)
        }
    }
    
    private func deleteItem(withID id: String)
    {
        guard let item = itemHash[id] else { return }
        
        itemHash.remove(item.array)
        
        if let parent = item.root
        {
            parent.removeNodes(from: [item.position])
        }
        else if roots[item.id] != nil
        {
            roots.remove([item])
        }
        else
        {
            removeOrphan(withID: item.id)
        }
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
    
    // MARK: - Orphans
    
    @discardableResult
    private func removeOrphan(withID id: ItemData.ID) -> Bool
    {
        for parentID in orphansByParentID.keys
        {
            if orphansByParentID[parentID]?[id] != nil
            {
                orphansByParentID[parentID]?[id] = nil
                return true
            }
        }
        
        return false
    }
    
    private func updateOrphan(_ orphan: Update)
    {
        guard let parentID = orphan.parentID, itemHash[parentID] == nil else
        {
            log(error: "Tried to save ItemUpdate as orphan, but it isn't an orphan")
            return
        }
        
        if orphansByParentID[parentID] == nil
        {
            orphansByParentID[parentID] = [orphan.data.id : orphan]
        }
        else
        {
            orphansByParentID[parentID]?[orphan.data.id] = orphan
        }
    }
    
    private var orphansByParentID = [ItemData.ID : [ItemData.ID : Update]]()
    
    // MARK: - Updates
    
    private func sortedByPosition(_ updates: [Update]) -> [Update]
    {
        return updates.sorted { $0.position < $1.position }
    }
    
    struct Update
    {
        func wouldChange(_ item: Item) -> Bool
        {
            if item.id != data.id { return false }
            if item.data != data { return false }
            if item.position != position { return false }
            if item.parentID != parentID { return false }
            return true
        }
        
        let data: ItemData
        let parentID: ItemData.ID?
        let position: Int
    }
    
    // MARK: - Item Storage
    
    private(set) var root: Item?
    private let roots = HashMap()
    private let itemHash = HashMap()
}

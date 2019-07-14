import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemStore: Observer, CustomObservable
{
    // MARK: - Initialization
    
    static let shared = ItemStore()
    private init() { observeRootStore() }
    
    // MARK: - Update Items
    
    func apply(updates: [Update])
    {
        DispatchQueue.main.async
        {
            updates.sortedByPosition.forEach(self.apply)
            
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
    
    // MARK: Update Existing Item
    
    private func apply(_ update: Update, to item: Item)
    {
        guard update.wouldChange(item) else { return }
        
        item.data.text <- update.data.text.value
        item.data.state <- update.data.state.value
        item.data.tag <- update.data.tag.value
        
        move(item, toNewTreePositionWith: update)
    }
    
    private func move(_ item: Item, toNewTreePositionWith update: Update)
    {
        if item.parentID == nil && update.parentID == nil
        {
            if orphanage.removeOrphan(with: item.id) { rootStore.add(item) }
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
            rootStore.add(item)
            return
        }

        rootStore.remove(item)
        
        if let newParent = itemHash[newParentID]
        {
            newParent.insert(item, at: update.position)
            
            orphanage.removeOrphan(with: item.id, parentID: newParentID)
        }
        else
        {
            orphanage.update(update, withParentID: newParentID)
        }
    }
    
    // MARK: Create New Item
    
    private func createItem(from update: Update)
    {
        let item = Item(data: update.data)
        itemHash.add([item])
        
        if let lostChildren = orphanage.orphans(forParentID: item.id)
        {
            lostChildren.sortedByPosition.forEach
            {
                guard let child = itemHash[$0.data.id] else { return }
                item.insert(child, at: $0.position)
            }
            
            orphanage.removeOrphans(forParentID: item.id)
        }
        
        if let parentID = update.parentID
        {
            if let parent = itemHash[parentID]
            {
                parent.insert(item, at: update.position)
            }
            else
            {
                orphanage.update(update, withParentID: parentID)
            }
        }
        else
        {
            rootStore.add(item)
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
        else if rootStore[item.id] != nil
        {
            rootStore.remove(item)
        }
        else
        {
            orphanage.removeOrphan(with: item.id)
        }
    }

    // MARK: - LEGACY: Manage Root
    
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
    
    // MARK: - Track Number of User Created Leafs
    
    private func updateUserCreatedLeafs(with root: Item)
    {
        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var(0)
    
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
    
    // MARK: - Orphans
    
    // TODO: observe ALL technical roots, including orphans
    let orphanage = Orphanage()
    
    // MARK: - Roots
    
    private func observeRootStore()
    {
        observe(rootStore)
        {
            [weak self] in
            
            guard let treeUpdate = $0 else { return }
            
            self?.send(.didUpdate(treeUpdate))
        }
    }
    
    private(set) var root: Item?
    private let rootStore = RootStore()
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    
    enum Event
    {
        case didSwitchRoot, didUpdate(Item.Event.TreeUpdate)
    }
    
    // MARK: - Item Storage

    private let itemHash = HashMap()
}

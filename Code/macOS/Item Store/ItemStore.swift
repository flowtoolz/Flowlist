import PromiseKit
import SwiftObserver
import SwiftyToolz

class ItemStore: Observer, CustomObservable
{
    // MARK: - Initialization
    
    static let shared = ItemStore()
    private init() {}
    
    // MARK: - Update (Save) Items
    
    func apply(updates: [Update])
    {
        DispatchQueue.main.async
        {
            updates.sortedByPosition.forEach(self.apply)
        }
    }
    
    private func apply(_ update: Update)
    {
        if let item = allItems[update.data.id]
        {
            let wasRootBeforeUpdate = item.isRoot
            apply(update, to: item)
            let isRootAfterUpdate = item.isRoot
            
            if wasRootBeforeUpdate != isRootAfterUpdate
            {
                if isRootAfterUpdate
                {
                    observe(technicalRoot: item)
                }
                else
                {
                    stopObserving(item.treeMessenger)
                }
            }
        }
        else
        {
            let item = createItem(from: update)
            if item.isRoot { observe(technicalRoot: item) }
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
            if orphans.removeOrphan(with: item.id) { roots.add(item) }
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
            roots.add(item)
            return
        }

        roots.remove(item)
        
        if let newParent = allItems[newParentID]
        {
            newParent.insert(item, at: update.position)
            
            orphans.removeOrphan(with: item.id, parentID: newParentID)
        }
        else
        {
            orphans.update(update, withParentID: newParentID)
        }
    }
    
    // MARK: Create New Item
    
    private func createItem(from update: Update) -> Item
    {
        let item = Item(data: update.data)
        allItems.add([item])
        
        if let lostChildren = orphans.orphans(forParentID: item.id)
        {
            lostChildren.sortedByPosition.forEach
            {
                guard let child = allItems[$0.data.id] else { return }
                item.insert(child, at: $0.position)
            }
            
            orphans.removeOrphans(forParentID: item.id)
        }
        
        if let parentID = update.parentID
        {
            if let parent = allItems[parentID]
            {
                parent.insert(item, at: update.position)
            }
            else
            {
                orphans.update(update, withParentID: parentID)
            }
        }
        else
        {
            roots.add(item)
        }
        
        return item
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
        guard let item = allItems[id] else { return }
        
        if item.isRoot { stopObserving(item.treeMessenger) }
        
        allItems.remove(item.array)
        
        if let parent = item.root
        {
            parent.removeNodes(from: [item.position])
        }
        else if roots[item.id] != nil
        {
            roots.remove(item)
        }
        else
        {
            orphans.removeOrphan(with: item.id)
        }
    }

    // MARK: - Observe ALL Technical Roots
    
    private func observe(technicalRoot root: Item)
    {
        guard root.isRoot else { return }
        
        observe(root.treeMessenger)
        {
            [weak self, weak root] event in
            
            guard case .didUpdateTree(let treeUpdate) = event, let root = root else { return }
            
            self?.didReceive(treeUpdate, from: root)
        }
    }
    
    private func didReceive(_ treeUpdate: Item.Event.TreeUpdate, from root: Item)
    {
        // TODO: keep orphanage and root hashmap in sync with edits from user
        switch treeUpdate
        {
        case .insertedNodes(let items, _, _):
            var hadAlreadyAddedThemWhenApplyingUpdates = true // were by record controller
            
            for item in items
            {
                if allItems[item.id] == nil
                {
                    hadAlreadyAddedThemWhenApplyingUpdates = false
                    allItems.add(item.array)
                }
            }
            
            if !hadAlreadyAddedThemWhenApplyingUpdates
            {
                send(treeUpdate)
            }
            
        case .receivedMessage, .movedNode:
            // TODO: avoid sending updates back that were triggered from outside (from database)
            send(treeUpdate)
            
        case .removedNodes(let items, _):
            var hadAlreadyRemovedAll = true  // were removed by record controller -> not in hashmap anymore
            
            for item in items
            {
                if allItems[item.id] != nil
                {
                    hadAlreadyRemovedAll = false
                    allItems.remove(item.array)
                }
            }
            
            if !hadAlreadyRemovedAll
            {
                send(treeUpdate)
            }
        }
    }
    
    // MARK: - Storage
    
    private let allItems = HashMap()
    private let roots = HashMap()
    private let orphans = Orphanage()
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Item.Event.TreeUpdate?
}

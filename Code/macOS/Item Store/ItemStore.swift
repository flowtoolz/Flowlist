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
                guard let child = allItems[$0.data.id] else
                {
                    log(warning: "ItemStore has a registered orphan for which it has no corresponding item. The orphan is gonna be removed.")
                    return
                }
                
                item.insert(child, at: $0.position)
                stopObserving(child.treeMessenger)
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
        
        allItems.remove(item.allNodesRecursively)
        
        if let parent = item.root
        {
            parent.removeNodes(from: [item.position])
        }
        else
        {
            if roots.contains(item)
            {
                roots.remove(item)
            }
            else
            {
                orphans.removeOrphan(with: item.id)
            }
            
            stopObserving(item.treeMessenger)
        }
    }

    // MARK: - Observe ALL Technical Roots
    
    private func observe(technicalRoot root: Item)
    {
        guard root.isRoot else { return }
        
        observe(root.treeMessenger)
        {
            [weak self] event in
            
            guard case .didUpdateTree(let treeUpdate) = event else { return }
            
            self?.technicalRootDidSend(treeUpdate)
        }
    }
    
    private func technicalRootDidSend(_ treeUpdate: Item.Event.TreeUpdate)
    {
        switch treeUpdate
        {
        case .receivedMessage, .movedNode:
            break
            
        case .insertedNodes(let items, let parent, _):
            if !allItems.contains(parent)
            {
                log(warning: "Inserted items into a parent which is not registered in ItemStore.")
                allItems.add(parent)
                if parent.isRoot
                {
                    roots.add(parent)
                    observe(technicalRoot: parent)
                }
            }
            
            items.forEach { allItems.add($0.allNodesRecursively) }
            
            roots.remove(items)
            items.forEach { stopObserving($0.treeMessenger) }
            
        case .removedNodes(let items, let parent):
            if !allItems.contains(parent)
            {
                log(warning: "Removed items from a parent which is not registered in ItemStore.")
                allItems.add(parent)
                if parent.isRoot
                {
                    roots.add(parent)
                    observe(technicalRoot: parent)
                }
            }
            
            items.forEach { allItems.remove($0.allNodesRecursively) }
            
            roots.remove(items)
            items.forEach { stopObserving($0.treeMessenger) }
        }
        
        send(treeUpdate)
    }
    
    // MARK: - Storage
    
    private let allItems = HashMap()
    private let roots = HashMap()
    private let orphans = Orphanage()
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Item.Event.TreeUpdate?
}

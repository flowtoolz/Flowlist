import PromiseKit
import SwiftObserver
import SwiftyToolz

class TreeStore: Observer, CustomObservable
{
    // MARK: - Initialization
    
    static let shared = TreeStore()
    private init() {}
    
    // MARK: - Add Items
    
    var count: Int { return trees.count }
    
    func add(_ item: Item)
    {
        allItems.add(item)
        insertOrphansInto(potentialParent: item)
        if item.isRoot { add(tree: item) }
    }
    
    // MARK: - Update (Save) Items
    
    func apply(updates: [Update])
    {
        updates.sortedByPosition.forEach(self.apply)
    }
    
    private func apply(_ update: Update)
    {
        if let item = allItems[update.data.id]
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
            if orphans.removeOrphan(with: item.id) { add(tree: item) }
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
            add(tree: item)
            return
        }

        remove(tree: item)
        
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
    
    private func createItem(from update: Update)
    {
        let item = Item(data: update.data)
        allItems.add([item])
        
        insertOrphansInto(potentialParent: item)
        
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
            add(tree: item)
        }
    }
    
    private func insertOrphansInto(potentialParent item: Item)
    {
        guard let lostChildren = orphans.orphans(forParentID: item.id) else { return }
        
        lostChildren.sortedByPosition.forEach
        {
            guard let child = allItems[$0.data.id] else
            {
                log(warning: "ItemStore has orphan without corresponding item.")
                return
            }
            
            item.insert(child, at: $0.position)
        }
        
        orphans.removeOrphans(forParentID: item.id)
    }
    
    // MARK: - Delete Items
    
    func deleteItems(withIDs ids: [ItemData.ID])
    {
        ids.forEach(self.deleteItem)
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
            if trees.contains(item)
            {
                remove(tree: item)
            }
            else
            {
                orphans.removeOrphan(with: item.id)
            }
        }
    }
    
    // MARK: - Manage Trees
    
    private func add(tree: Item)
    {
        guard tree.isRoot, !trees.contains(tree) else { return }
        trees.add(tree)
        observe(tree: tree)
        send(.didAddTree(tree))
    }
    
    private func observe(tree: Item)
    {
        guard tree.isRoot else { return }
        
        observe(tree.treeMessenger)
        {
            [weak self] event in
            
            guard case .didUpdateTree(let treeUpdate) = event else { return }
            
            self?.treeDidSend(treeUpdate)
        }
    }
    
    private func treeDidSend(_ treeUpdate: Item.Event.TreeUpdate)
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
                if parent.isRoot { add(tree: parent) }
            }
            
            items.forEach
            {
                allItems.add($0.allNodesRecursively)
                remove(tree: $0)
            }
            
        case .removedNodes(let items, let parent):
            if !allItems.contains(parent)
            {
                log(warning: "Removed items from a parent which is not registered in ItemStore.")
                allItems.add(parent)
                if parent.isRoot { add(tree: parent) }
            }
            
            items.forEach
            {
                allItems.remove($0.allNodesRecursively)
                remove(tree: $0)
            }
        }
        
        send(.someTreeDidChange(treeUpdate))
    }
    
    private func remove(tree: Item)
    {
        guard trees.contains(tree) else { return }
        trees.remove(tree)
        stopObserving(tree.treeMessenger)
        send(.didRemoveTree(tree))
    }
    
    private let trees = HashMap()
    
    // MARK: - Other Storage
    
    private let allItems = HashMap()
    private let orphans = Orphanage()
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    enum Event { case someTreeDidChange(Item.Event.TreeUpdate), didAddTree(Item), didRemoveTree(Item) }
}

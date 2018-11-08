import SwiftObserver

class Store: Observer, Observable
{
    // MARK: - Initialization
    
    static let shared = Store() 
    
    fileprivate init() {}

    // MARK: - Update Root
    
    func update(root newRoot: Item)
    {
        stopObserving(root)
        observe(newRoot: newRoot)
        itemHash.reset(with: newRoot.array)
        updateUserCreatedLeafs(with: newRoot)
        
        root = newRoot
        
        pasteWelcomeTourIfRootIsEmpty()
        
        send(.didSwitchRoot)
    }
    
    private func observe(newRoot: Item)
    {
        observe(newRoot)
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
                    if itemHash[item.data.id] == nil
                    {
                        hadAlreadyAddedAll = false
                        itemHash.add(item.array)
                    }
                }
                
                if !hadAlreadyAddedAll
                {
                    sendEdit(with: treeUpdate)
                }
                
            case .receivedDataUpdate, .movedNode:
                // TODO: avoid sending updates back that were triggered from outside (from database)
                sendEdit(with: treeUpdate)
                
            case .removedNodes(let items, _):
                var hadAlreadyRemovedAll = true
                
                for item in items
                {
                    if itemHash[item.data.id] != nil
                    {
                        hadAlreadyRemovedAll = false
                        itemHash.remove(item.array)
                    }
                }
                
                if !hadAlreadyRemovedAll
                {
                    sendEdit(with: treeUpdate)
                }
            }
        }
    }
    
    private func sendEdit(with treeUpdate: Item.Event.TreeUpdate)
    {
        if let edit = Edit(from: treeUpdate)
        {
            send(.wasEdited(edit))
        }
    }
    
    // MARK: - Welcome Tour
    
    func pasteWelcomeTourIfRootIsEmpty()
    {
        guard let root = root else
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
    
    let numberOfUserCreatedLeafs = Var<Int>()
    
    // MARK: - Item Storage
    
    private(set) var root: Item?
    let itemHash = HashMap()
    
    // MARK: - Observability
    
    var latestUpdate = Event.didNothing
    
    enum Event
    {
        case didNothing, didSwitchRoot, wasEdited(Edit)
    }
}

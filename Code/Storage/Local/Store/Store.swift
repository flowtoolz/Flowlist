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
                for item in items { itemHash.add(item.array) }
                
            case .receivedDataUpdate: break
                
            case .removedNodes(let items, _):
                for item in items { itemHash.remove(item.array) }
            }
            
            if let interaction = Item.Interaction(from: treeUpdate)
            {
                send(.wasInteractedWith(interaction))
            }
        }
    }
    
    // MARK: - Welcome Tour
    
    func pasteWelcomeTourIfRootIsEmpty()
    {
        if root == nil
        {
            update(root: Item(text: NSUserName()))
        }
        
        if root?.isLeaf ?? false
        {
            root?.insert(Item.welcomeTour, at: 0)
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
    
    var latestUpdate = StoreEvent.didNothing
}

enum StoreEvent
{
    case didNothing, didSwitchRoot, wasInteractedWith(Item.Interaction)
}

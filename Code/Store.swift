import SwiftObserver

class Store: Observer, Observable
{
    // MARK: - Initialization
    
    static let shared = Store() 
    
    fileprivate init() {}

    // MARK: - Update Root
    
    func update(root newRoot: ItemDataTree)
    {
        stopObserving(root?.treeMessenger)
        observe(newRoot: newRoot)
        itemHash.reset(with: newRoot.array)
        updateUserCreatedLeafs(with: newRoot)
        
        root = newRoot
        
        send(.didSwitchRoot)
    }
    
    private func observe(newRoot: ItemDataTree)
    {
        observe(newRoot.treeMessenger)
        {
            [weak self, weak newRoot] event in
            
            guard let newRoot = newRoot else { return }
            
            self?.didReceive(event, from: newRoot)
        }
    }
    
    private func didReceive(_ event: ItemDataTree.TreeEvent,
                            from root: ItemDataTree)
    {
        switch event
        {
        case .didNothing, .didSwitchData: break
            
        case .did(let edit):
            if edit.modifiesContent
            {
                updateUserCreatedLeafs(with: root)
            }
            
        case .didChange(_):
            updateUserCreatedLeafs(with: root)
            
        case .rootEvent(let rootEvent):
            switch rootEvent
            {
            case .didRemove(let items):
                for item in items { itemHash.remove(item.array) }
            case .didInsert(let items, _, _):
                for item in items { itemHash.add(item.array) }
            }
        }
    }
    
    // MARK: - Welcome Tour
    
    func pasteWelcomeTourIfRootIsEmpty()
    {
        if root == nil
        {
            update(root: ItemDataTree(NSUserName()))
        }
        
        if root?.isLeaf ?? false
        {
            root?.insert(Item.welcomeTour, at: 0)
        }
    }
    
    // MARK: - Track Number of User Created Leafs
    
    private func updateUserCreatedLeafs(with root: ItemDataTree)
    {
        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var<Int>()
    
    // MARK: - Item Storage
    
    private(set) var root: ItemDataTree?
    let itemHash = HashMap()
    
    // MARK: - Observability
    
    var latestUpdate = StoreEvent.didNothing
}

enum StoreEvent { case didNothing, didSwitchRoot }

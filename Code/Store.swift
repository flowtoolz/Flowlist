import SwiftObserver

protocol StoreInterface: Observable where UpdateType == StoreEvent
{
    func updateItem(with edit: ItemEdit)
    func set(newRoot: Item)
}

class Store: Observer, Observable
{
    // MARK: - Initialization
    
    static let shared = Store() 
    
    fileprivate init() {}
    
    deinit
    {
        stopAllObserving()
        removeObservers()
    }

    // MARK: - Update Root
    
    func set(newRoot: Item)
    {
        stopObserving(root)
        observe(newRoot: newRoot)
        itemHash.reset(with: newRoot.array)
        
        // FIXME: all hell break lose updating leafs... :D
        //updateUserCreatedLeafs(with: newRoot)
        
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
            
        case .didNothing, .didChangeData: break
            
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
            set(newRoot: Item(NSUserName()))
        }
        
        if root?.isLeaf ?? false
        {
            root?.insert(Item.welcomeTour, at: 0)
        }
    }
    
    // MARK: - Hash Map
    
    let itemHash = ItemHash()
    
    // MARK: - Count Leafs Inside Root
    
    private func updateUserCreatedLeafs(with root: Item)
    {
        root.debug()
        
        // FIXME: all hell breaks lose with this:
//        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var<Int>()
    
    // MARK: - Root
    
    private(set) var root: Item?
    
    // MARK: - Observability
    
    var latestUpdate = StoreEvent.didNothing
}

enum StoreEvent { case didNothing, didSwitchRoot }

class ItemHash
{
    var items: [Item]
    {
        return Array(storedItems.values)
    }
    
    subscript(_ id: String) -> Item?
    {
        return storedItems[id]
    }
    
    func reset(with items: [Item])
    {
        storedItems.removeAll()
        
        add(items)
    }
    
    func add(_ items: [Item])
    {
        for item in items
        {
            guard let data = item.data else { return }
            
            storedItems[data.id] = item
        }
    }
    
    func remove(_ items: [Item])
    {
        for item in items
        {
            guard let data = item.data else { return }
            
            storedItems[data.id] = nil
        }
    }
    
    private var storedItems = [String : Item]()
}

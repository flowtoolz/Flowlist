import SwiftObserver

class Store: StoreInterface, Observer
{
    // MARK: - Initialization
    
    static let shared = Store() 
    
    fileprivate init()
    {
        observe(newRoot: root)
        resetHashMap(with: root)
        updateUserCreatedLeafs(with: root)
    }

    // MARK: - Root
    
    var root = Item()
    {
        didSet
        {
            stopObserving(oldValue)
            observe(newRoot: root)
            resetHashMap(with: root)
            updateUserCreatedLeafs(with: root)
        }
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
                for item in items { removeFromHashMap(item.array) }
            case .didInsert(let items, _, _):
                for item in items { addToHashMap(item.array) }
            }
        }
    }
    
    // MARK: - Welcome Tour
    
    func pasteWelcomeTourIfRootIsEmpty()
    {
        if root.isLeaf
        {
            root.insert(Item.welcomeTour, at: 0)
        }
    }
    
    // MARK: - Hash Map
    
    private func resetHashMap(with newRoot: Item)
    {
        hashMap.removeAll()
        
        addToHashMap(newRoot.array)
    }
    
    private func addToHashMap(_ items: [Item])
    {
        for item in items
        {
            guard let data = item.data else { return }
            
            hashMap[data.id] = item
        }
    }
    
    private func removeFromHashMap(_ items: [Item])
    {
        for item in items
        {
            guard let data = item.data else { return }
            
            hashMap[data.id] = nil
        }
    }
    
    private var hashMap = [String : Item]()
    
    // MARK: - Count Leafs Inside Root
    
    private func updateUserCreatedLeafs(with root: Item)
    {
        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var<Int>()
}

typealias PersistableStore = Persistable & StoreInterface

protocol StoreInterface: AnyObject {}

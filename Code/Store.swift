import SwiftObserver

typealias PersistableStore = Persistable & StoreInterface

extension Store: StoreInterface
{
    func updateItem(with edit: ItemEdit)
    {
        // TODO: be aware that, on modification, icloud always sends root and text, even if they weren't modified
        
        switch edit
        {
        case .didNothing: break
            
        case .didCreate(let info):
            let newItem = Item(data: info.data)
            
            hashMap[info.data.id] = newItem
            
            if let rootId = info.rootId,
                let rootItem = hashMap[rootId]
            {
                rootItem.add(newItem)
            }
            
        case .didModify(let info):
            let id = info.data.id
            
            guard let item = hashMap[id] else { break }
            
            for field in info.modified
            {
                switch field
                {
                case .text:
                    item.data?.text <- info.data.text.value

                case .state:
                    item.data?.state <- info.data.state.value
                    
                case .tag:
                    item.data?.tag <- info.data.tag.value
                
                case .root: break
                }
            }
            
        case .didDelete(let id): removeItem(with: id)
        }
    }
    
    private func removeItem(with id: String)
    {
        guard let item = hashMap[id] else { return }
        
        removeFromHashMap([item])
        
        guard let superItem = item.root,
            let index = item.indexInRoot else { return }
        
        superItem.removeNodes(from: [index])
    }
    
    func set(newRoot: Item)
    {
        stopObserving(root)
        observe(newRoot: newRoot)
        resetHashMap(with: newRoot)
        
        // FIXME: all hell break lose updating leafs... :D
        //updateUserCreatedLeafs(with: newRoot)
        
        root = newRoot
        
        send(.didSwitchRoot)
    }
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

protocol StoreInterface: Observable where UpdateType == StoreEvent
{
    func updateItem(with edit: ItemEdit)
    func set(newRoot: Item)
}

enum StoreEvent { case didNothing, didSwitchRoot }

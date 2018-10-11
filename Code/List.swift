import SwiftObserver
import SwiftyToolz

class List: Observable, Observer
{
    // MARK: - Life Cycle
    
    init()
    {
        observe(isFocused)
        {
            [weak self] _ in self?.updateFocusOfItems()
        }
    }
    
    deinit
    {
        stopAllObserving()
        removeObservers()
    }
    
    // MARK: - Configuration
    
    func set(root newRoot: Item?)
    {
        guard newRoot !== root else
        {
            log(warning: "Tried to set identical root in item list.")
            return
        }
        
        observeItems(with: root, start: false)
        observeItems(with: newRoot)
        
        root = newRoot
    }
    
    private func observeItems(with root: Item?, start: Bool = true)
    {
        guard let root = root else
        {
            if !start  { stopObservingDeadObservables() }
            return
        }
        
        observe(root: root, start: start)
        observeItemsListed(in: root, start: start)
    }
    
    // MARK: - Observe Root
    
    private func observe(root: Item, start: Bool = true)
    {
        guard start else
        {
            stopObserving(root)
            return
        }
        
        observe(root)
        {
            [weak self, weak root] event in
            
            guard let root = root else { return }
            
            switch event
            {
            case .didNothing: break
            case .did(let edit): self?.received(edit, from: root)
            case .didChangeData(from: _, to: let newItemData):
                self?.title.observable = newItemData?.title
            case .didChange(numberOfLeafs: _): break
            }
        }
    }
    
    func received(_ edit: Item.Edit, from root: Item)
    {
        switch edit
        {
        case .insert(let indexes):
            observeItemsListed(in: root, at: indexes)
            
        case .remove(let items, let indexes):
            deselectItems(at: indexes)
            for item in items { observe(listedItem: item, start: false) }
            
        case .move: break
            
        case .nothing, .changeRoot: return
        }
        
        send(.did(edit))
    }
    
    // MARK: - Observe Listed Items
    
    private func observeItemsListed(in root: Item, start: Bool = true)
    {
        let indexes = Array(0 ..< root.count)
        
        observeItemsListed(in: root, at: indexes, start: start)
    }
    
    private func observeItemsListed(in root: Item,
                                    at indexes: [Int],
                                    start: Bool = true)
    {
        for index in indexes
        {
            guard let item = root[index] else { continue }
            
            observe(listedItem: item, start: start)
        }
    }
    
    private func observe(listedItem item: Item, start: Bool = true)
    {
        guard start else
        {
            stopObserving(item.data?.state)
            
            return
        }
        
        if let state = item.data?.state
        {
            observe(state)
            {
                [weak self, weak item] _ in self?.itemDidChangeState(item)
            }
        }
    }
    
    private func itemDidChangeState(_ item: Item?)
    {
        guard let item = item, let index = item.indexInRoot else { return }
        
        if item.isDone
        {
            root?.moveSubitemToTopOfDoneList(from: index)
        }
        else if item.isInProgress
        {
            root?.moveNode(from: index, to: 0)
        }
        else if item.isUndone
        {
            root?.moveSubitemToTopOfUndoneList(from: index)
        }
    }
    
    // MARK: - Title
    
    func editTitle(at index: Int)
    {
        guard index >= 0, index < count else
        {
            log(warning: "Tried to edit title at invalid index \(index).")
            return
        }
        
        self[index]?.data?.send(.wantTextInput)
    }
    
    let title = Var<String>().new()
    
    // MARK: - Focus
    
    private func updateFocusOfItems()
    {
        let focused = isFocused.value ?? false
        
        for itemIndex in 0 ..< count
        {
            self[itemIndex]?.data?.set(isFocused: focused)
        }
    }
    
    let isFocused = Var(false)
    
    // MARK: - Listed Items
    
    subscript(_ index: Int) -> Item?
    {
        guard let root = root else
        {
            log(warning: "Tried to get item at \(index) from list without root.")
            return nil
        }
        
        return root[index]
    }
    
    var count: Int { return root?.count ?? 0 }
    
    // MARK: - Root
    
    var isRootList: Bool { return root != nil && root?.root == nil }
    
    private(set) weak var root: Item?
    {
        didSet
        {
            guard oldValue !== root else { return }

            didSwitchRoot(from: oldValue, to: root)
        }
    }
    
    private func didSwitchRoot(from old: Item?, to new: Item?)
    {
        old?.lastRemoved.removeAll()
        
        title.observable = new?.data?.title
        
        send(.did(.changeRoot(from: old, to: new)))
    }
    
    // MARK: - Atomic Selection Operations
    
    func setSelectionWithItemsListed(at newIndexes: [Int])
    {
        var newSelections = Array<Bool>(repeating: false, count: count)
        
        for selectedIndex in newIndexes
        {
            newSelections[selectedIndex] = true
        }
        
        for index in 0 ..< count
        {
            self[index]?.data?.set(isSelected: newSelections[index])
        }
        
        send(.didChangeSelection)
    }
    
    func selectItem(at index: Int)
    {
        guard let data = self[index]?.data, !data.isSelected.latestUpdate else
        {
            return
        }
        
        data.set(isSelected: true)
        
        send(.didChangeSelection)
    }
    
    func toggleSelection(at index: Int)
    {
        guard let data = self[index]?.data else { return }
        
        let itemIsSelected = data.isSelected.latestUpdate
        data.set(isSelected: !itemIsSelected)
        
        send(.didChangeSelection)
    }
    
    func deselectItems(at indexes: [Int])
    {
        for index in indexes
        {
            self[index]?.data?.set(isSelected: false)
        }
        
        send(.didChangeSelection)
    }
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing
        case did(Item.Edit)
        case didChangeSelection
    }
}

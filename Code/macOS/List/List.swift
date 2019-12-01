import SwiftObserver
import SwiftyToolz

class List: Observable, Observer
{
    // MARK: - Life Cycle
    
    init(isRoot: Bool)
    {
        isRootList = isRoot
        
        observe(isFocused)
        {
            [weak self] _ in self?.updateFocusOfItems()
        }
    }
    
    deinit { stopObserving() }
    
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
        guard let root = root else { return }
        
        observe(root: root, start: start)
        observeItemsListed(in: root, start: start)
    }
    
    // MARK: - Observe Root
    
    private func observe(root: Item, start: Bool = true)
    {
        guard start else
        {
            stopObserving(root.treeMessenger)
            return
        }
        
        observe(root.treeMessenger)
        {
            [weak self, weak root] event in
            
            guard let root = root else { return }
            
            switch event
            {
            case .didUpdateTree: break
            case .didUpdateNode(let edit): self?.received(edit, from: root)
            case .didChangeLeafNumber(numberOfLeafs: _): break
            }
        }
    }
    
    func received(_ edit: Item.Event.NodeUpdate, from root: Item)
    {
        switch edit
        {
        case .insertedNodes(let firstPosition, let lastPosition):
            observeItemsListed(in: root, from: firstPosition, to: lastPosition)
            
        case .removedNodes(let items, let indexes):
            var selectionDidChange = false
            
            items.forEach
            {
                observe(listedItem: $0, start: false)
                if $0.isSelected { selectionDidChange = true }
            }
            
            if selectionDidChange
            {
                send(.didChangeSelection(added: [], removed: indexes))
            }
            
        case .movedNode: break
            
        case .switchedParent: return
        }
        
        send(.did(edit))
    }
    
    // MARK: - Observe Listed Items
    
    private func observeItemsListed(in root: Item, start: Bool = true)
    {
        guard root.count > 0 else { return }
        
        observeItemsListed(in: root, from: 0, to: root.count - 1, start: start)
    }
    
    private func observeItemsListed(in root: Item,
                                    from firstPosition: Int,
                                    to lastPosition: Int,
                                    start: Bool = true)
    {
        guard lastPosition < root.count else { return }
        
        for index in firstPosition ... lastPosition
        {
            guard let item = root[index] else { continue }
            
            observe(listedItem: item, start: start)
        }
    }
    
    private func observe(listedItem item: Item, start: Bool = true)
    {
        guard start else
        {
            stopObserving(item.data.state)
            
            return
        }
        
        observe(item.data.state)
        {
            [weak self, weak item] _ in self?.itemDidChangeState(item)
        }
    }
    
    private func itemDidChangeState(_ item: Item?)
    {
        guard let item = item, let index = item.indexInParent else { return }
        
        if item.isDone
        {
            root?.moveSubitemToTopOfDoneList(from: index)
        }
        else if item.isInProgress
        {
            root?.moveChild(from: index, to: 0)
        }
        else if item.isUndone
        {
            root?.moveSubitemToTopOfUndoneList(from: index)
        }
    }
    
    // MARK: - Title
    
    func editText(at index: Int)
    {
        guard index >= 0, index < count else
        {
            log(warning: "Tried to edit text at invalid index \(index).")
            return
        }
        
        self[index]?.edit()
    }
    
    // MARK: - Focus
    
    private func updateFocusOfItems()
    {
        let focused = isFocused.value
        
        for itemIndex in 0 ..< count
        {
            self[itemIndex]?.isFocused = focused
        }
    }
    
    let isFocused = Var(false)
    
    // MARK: - Listed Items
    
    subscript(_ index: Int?) -> Item?
    {
        guard let index = index else { return nil }
        
        guard let root = root else
        {
            log(warning: "Tried to get item at \(index) from list without root.")
            return nil
        }
        
        return root[index]
    }
    
    var count: Int { root?.count ?? 0 }
    
    // MARK: - Root
    
    let isRootList: Bool
    
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
        old?.deletionStack.removeAll()
        old?.deselectAll()
        
        title <- new?.text
        tag <- new?.data.tag.value
        state <- new?.data.state.value
        
        send(.did(.switchedParent(from: old, to: new)))
    }
    
    // MARK: - Mappings
    
    let tag = Var<ItemData.Tag?>()
    let title = Var<String?>()
    let state = Var<ItemData.State?>()
    
    // MARK: - Atomic Selection Operations
    
    func setSelectionWithItemsListed(at newIndexes: [Int])
    {
        var newSelections = Array<Bool>(repeating: false, count: count)
        
        newIndexes.forEach { newSelections[$0] = true }
        
        var addedIndexes = [Int]()
        var removedIndexes = [Int]()
        
        for index in 0 ..< count
        {
            let item = self[index]
            let shouldSelect = newSelections[index]
            
            if item?.isSelected != shouldSelect
            {
                if shouldSelect
                {
                    addedIndexes.append(index)
                }
                else
                {
                    removedIndexes.append(index)
                }
                
                item?.isSelected = shouldSelect
            }
        }
        
        if !addedIndexes.isEmpty || !removedIndexes.isEmpty
        {
            send(.didChangeSelection(added: addedIndexes, removed: removedIndexes))
        }
    }
    
    func selectItem(at index: Int)
    {
        guard let item = self[index], !item.isSelected else
        {
            return
        }
        
        item.isSelected = true
        
        send(.didChangeSelection(added: [index], removed: []))
    }
    
    func toggleSelection(at index: Int)
    {
        guard let item = self[index] else { return }
        
        item.isSelected = !item.isSelected
        
        if !item.isSelected
        {
            send(.didChangeSelection(added: [], removed: [index]))
        }
        else
        {
            send(.didChangeSelection(added: [index], removed: []))
        }
    }
    
    func selectItems(at indexes: [Int])
    {
        var addedIndexes = [Int]()
        
        for index in indexes
        {
            let item = self[index]
            
            if item?.isSelected == false
            {
                item?.isSelected = true
                
                addedIndexes.append(index)
            }
        }
        
        if !addedIndexes.isEmpty
        {
            send(.didChangeSelection(added: addedIndexes, removed: []))
        }
    }
    
    func deselectItems(at indexes: [Int])
    {
        var removedIndexes = [Int]()
        
        for index in indexes
        {
            let item = self[index]
            
            if item?.isSelected ?? false
            {
                item?.isSelected = false
                
                removedIndexes.append(index)
            }
        }
        
        if !removedIndexes.isEmpty
        {
            send(.didChangeSelection(added: [], removed: removedIndexes))
        }
    }
    
    // MARK: - Observability
    
    let messenger = Messenger<Event>()
    
    enum Event
    {
        case did(Item.Event.NodeUpdate)
        case didChangeSelection(added: [Int], removed: [Int])
    }
}

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
            log(warning: "Tried to set identical root in task list.")
            return
        }
        
        observeTasks(with: root, start: false)
        observeTasks(with: newRoot)
        
        root = newRoot
    }
    
    private func observeTasks(with root: Item?,
                              start: Bool = true)
    {
        guard let root = root else
        {
            if !start  { stopObservingDeadObservables() }
            return
        }
        
        observe(root: root, start: start)
        observeTasksListed(in: root, start: start)
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
            observeTasksListed(in: root, at: indexes)
            
        case .remove(let tasks, let indexes):
            deselectItems(at: indexes)
            for task in tasks { observe(listedTask: task, start: false) }
            
        case .move: break
            
        case .nothing, .changeRoot: return
        }
        
        send(.did(edit))
    }
    
    // MARK: - Observe Listed Tasks
    
    private func observeTasksListed(in root: Item, start: Bool = true)
    {
        let indexes = Array(0 ..< root.count)
        
        observeTasksListed(in: root, at: indexes, start: start)
    }
    
    private func observeTasksListed(in root: Item,
                                    at indexes: [Int],
                                    start: Bool = true)
    {
        for index in indexes
        {
            guard let task = root[index] else { continue }
            
            observe(listedTask: task, start: start)
        }
    }
    
    private func observe(listedTask task: Item, start: Bool = true)
    {
        guard start else
        {
            stopObserving(task.data?.state)
            
            return
        }
        
        if let state = task.data?.state
        {
            observe(state)
            {
                [weak self, weak task] _ in self?.taskDidChangeState(task)
            }
        }
    }
    
    private func taskDidChangeState(_ task: Item?)
    {
        guard let task = task, let index = task.indexInRoot else { return }
        
        if task.isDone
        {
            root?.moveSubtaskToTopOfDoneList(from: index)
        }
        else if task.isInProgress
        {
            root?.moveNode(from: index, to: 0)
        }
        else if task.isUndone
        {
            root?.moveSubtaskToTopOfUndoneList(from: index)
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
    
    // MARK: - Listed Tasks
    
    subscript(_ index: Int) -> Item?
    {
        guard let root = root else
        {
            log(warning: "Tried to get task at \(index) from list without root.")
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
    
    func setSelectionWithTasksListed(at newIndexes: [Int])
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
    
    func selectTask(at index: Int)
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

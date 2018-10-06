import SwiftObserver
import SwiftyToolz

class List: Observable, Observer
{
    // MARK: - Life Cycle
    
    deinit
    {
        stopAllObserving()
        removeObservers()
    }
    
    // MARK: - Configuration
    
    func set(root newRoot: Task?)
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
    
    private func observeTasks(with root: Task?, start: Bool = true)
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
    
    private func observe(root: Task, start: Bool = true)
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
            case .didChange(numberOfLeafs: _): break
            case .did(let edit): self?.received(edit, from: root)
            }
        }
    }
    
    func received(_ edit: Edit, from root: Task)
    {
        switch edit
        {
        case .insert(let indexes):
            observeTasksListed(in: root, at: indexes)
            
        case .remove(let tasks, _):
            for task in tasks { observe(listedTask: task, start: false) }
            
        case .create(let index):
            observeTasksListed(in: root, at: [index])
        
        case .move: break
            
        case .nothing, .changeRoot: return
        }
        
        send(.did(edit))
    }
    
    // MARK: - Observe Listed Tasks
    
    private func observeTasksListed(in root: Task,
                                    start: Bool = true)
    {
        let indexes = Array(0 ..< root.numberOfBranches)
        
        observeTasksListed(in: root, at: indexes, start: start)
    }
    
    private func observeTasksListed(in root: Task,
                                    at indexes: [Int],
                                    start: Bool = true)
    {
        for index in indexes
        {
            guard let task = root[index] else { continue }
            
            observe(listedTask: task, start: start)
        }
    }
    
    private func observe(listedTask task: Task, start: Bool = true)
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
    
    private func taskDidChangeState(_ task: Task?)
    {
        guard let task = task, let index = task.indexInRoot else { return }
        
        if task.isDone
        {
            root?.moveSubtaskToTopOfDoneList(from: index)
        }
        else if task.isInProgress
        {
            root?.moveSubtask(from: index, to: 0)
        }
        else if task.isUndone
        {
            root?.moveSubtaskToTopOfUndoneList(from: index)
        }
    }
    
    // MARK: - Title
    
    func editTitle(at index: Int)
    {
        guard index >= 0, index < numberOfTasks else
        {
            log(warning: "Tried to edit title at invalid index \(index).")
            return
        }
        
        send(.wantToEditTitle(at: index))
    }
    
    let title = Var<String>().new()
    
    // MARK: - Listed Tasks
    
    subscript(_ index: Int) -> Task?
    {
        guard let root = root else
        {
            log(warning: "Tried to get task at \(index) from list without root.")
            return nil
        }
        
        return root[index]
    }
    
    var numberOfTasks: Int { return root?.numberOfBranches ?? 0 }
    
    // MARK: - Root
    
    var isRootList: Bool { return root != nil && root?.root == nil }
    
    private(set) weak var root: Task?
    {
        didSet
        {
            guard oldValue !== root else { return }

            didSwitchRoot(from: oldValue, to: root)
        }
    }
    
    private func didSwitchRoot(from old: Task?, to new: Task?)
    {
        old?.lastRemoved.removeAll()
        
        title.observable = new?.data?.title
        
        send(.did(.changeRoot(from: old, to: new)))
    }
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, did(Edit), wantToEditTitle(at: Int) }
}

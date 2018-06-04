import SwiftObserver
import SwiftyToolz

class List: Observable, Observer
{
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
    
    deinit { stopAllObserving() }
    
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
            [weak self, weak root] edit in
            
            guard let root = root else { return }
            
            self?.received(edit, from: root)
        }
    }
    
    func received(_ edit: Edit, from root: Task)
    {
        switch edit
        {
        case .didInsert(let indexes):
            observeTasksListed(in: root, at: indexes)
            
        case .didRemove(let tasks, _):
            for task in tasks { observe(listedTask: task, start: false) }
            
        case .didCreate(let index):
            observeTasksListed(in: root, at: [index])
        
        case .didNothing, .didMove, .didChangeRoot: break
        }
        
        send(.did(edit: edit))
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
            stopObserving(task.state)
            
            return
        }
        
        observe(task.state)
        {
            [weak self, weak task] stateUpdate in
            
            if let task = task,
                stateUpdate.new != stateUpdate.old,
                let taskIndex = task.indexInRoot,
                task.isDone
            {
                self?.root?.moveSubtaskToTopOfDoneList(from: taskIndex)
            }
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
        title.observable = new?.title
        
        send(.did(edit: .didChangeRoot(from: old, to: new)))
        
        // TODO: do this as reaction to the event .didChangeRoot
        sendDidRemoveTasksOf(oldRoot: old)
        sendDidInsertTasksOf(newRoot: new)
    }
    
    private func sendDidRemoveTasksOf(oldRoot old: Task?)
    {
        guard let old = old, old.hasBranches else { return }

        var subtasks = [Task]()
        var indexes = [Int]()
        
        for index in 0 ..< old.numberOfBranches
        {
            if let subtask = old[index]
            {
                subtasks.append(subtask)
                indexes.append(index)
            }
        }
        
        send(.did(edit: .didRemove(subtasks: subtasks, from: indexes)))
    }
    
    private func sendDidInsertTasksOf(newRoot new: Task?)
    {
        guard let new = new, new.hasBranches else { return }
        
        let indexes = Array(0 ..< new.numberOfBranches)

        send(.did(edit: .didInsert(at: indexes)))
    }
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, did(edit: Edit), wantToEditTitle(at: Int) }
}

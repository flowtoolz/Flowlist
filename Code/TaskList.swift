import SwiftObserver
import SwiftyToolz

class TaskList: Observable, Observer
{
    // MARK: - Configuration
    
    func set(root newRoot: Task?)
    {
        guard newRoot !== root else
        {
            log(warning: "Tried to set identical root in task list.")
            return
        }
        
        //print("setting list root \(newRoot?.title.value ?? "untitled")")
        
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
        
        //print("observing tasks with root \(root.title.value ?? "untitled")")
        
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
        
        //print("start observing root \(root.title.value ?? "untitled")")
        
        observe(root)
        {
            [weak self, weak root] change in
            
            guard let root = root else { return }
            
            self?.received(change, from: root)
        }
    }
    
    func received(_ edit: ListEdit, from root: Task)
    {
        //print("list <\(root.title.value ?? "untitled")> \(change)")
        
        switch edit
        {
        case .didInsert(let indexes):
            observeTasksListed(in: root, at: indexes)
            
        case .didRemove(let tasks, _):
            for task in tasks { observe(listedTask: task, start: false) }
            
        default: break
        }
        
        send(edit)
    }
    
    // MARK: - Observe Listed Tasks
    
    private func observeTasksListed(in root: Task,
                                    start: Bool = true)
    {
        let indexes = Array(0 ..< root.numberOfSubtasks)
        
        observeTasksListed(in: root, at: indexes, start: start)
    }
    
    private func observeTasksListed(in root: Task,
                                    at indexes: [Int],
                                    start: Bool = true)
    {
        for index in indexes
        {
            guard let task = root.subtask(at: index) else { continue }
            
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
                let taskIndex = task.indexInSupertask,
                task.isDone
            {
                self?.root?.moveSubtaskToTopOfDoneList(from: taskIndex)
            }
        }
    }
    
    // MARK: - Listed Tasks
    
    func task(at index: Int) -> Task?
    {
        guard let root = root else
        {
            log(warning: "Tried to get task at \(index) from list without root.")
            return nil
        }
        
        return root.subtask(at: index)
    }
    
    var numberOfTasks: Int
    {
        guard let root = root else
        {
            log(warning: "Tried to get task number from list without root.")
            return 0
        }
        
        return root.numberOfSubtasks
    }
    
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
        //print("list changed root from \(old?.title.value ?? "untitled") to \(new?.title.value ?? "untitled")")
        
        title.observable = new?.title
        
        sendDidRemoveTasksOf(oldRoot: old)
        sendDidInsertTasksOf(newRoot: new)
    }
    
    private func sendDidRemoveTasksOf(oldRoot old: Task?)
    {
        guard let old = old, old.hasSubtasks else { return }

        var subtasks = [Task]()
        var indexes = [Int]()
        
        for index in 0 ..< old.numberOfSubtasks
        {
            if let subtask = old.subtask(at: index)
            {
                subtasks.append(subtask)
                indexes.append(index)
            }
        }
        
        send(.didRemove(subtasks: subtasks, from: indexes))
    }
    
    private func sendDidInsertTasksOf(newRoot new: Task?)
    {
        guard let new = new, new.hasSubtasks else { return }
        
        let indexes = Array(0 ..< new.numberOfSubtasks)

        send(.didInsert(at: indexes))
    }
    
    // MARK: - Title
    
    let title = Var<String>().new().unwrap("")
    
    // MARK: - Observability
    
    var latestUpdate: ListEdit { return .didNothing }
}

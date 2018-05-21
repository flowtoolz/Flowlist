import SwiftObserver
import SwiftyToolz

class TaskList: Observable, Observer
{
    // MARK: - Configuration
    
    func set(supertask newSupertask: Task?)
    {
        guard newSupertask !== supertask else
        {
            log(warning: "Tried to set identical supertask in task list.")
            return
        }
        
        //print("setting list supertask \(newSupertask?.title.value ?? "untitled")")
        
        observeTasks(with: supertask, start: false)
        observeTasks(with: newSupertask)
        
        supertask = newSupertask
    }
    
    private func observeTasks(with supertask: Task?, start: Bool = true)
    {
        guard let supertask = supertask else
        {
            if !start  { stopObservingDeadObservables() }
            return
        }
        
        //print("observing tasks with supertask \(supertask.title.value ?? "untitled")")
        
        observe(supertask: supertask, start: start)
        observeTasksListed(in: supertask, start: start)
    }
    
    deinit { stopAllObserving() }
    
    // MARK: - Observe Supertask
    
    private func observe(supertask: Task, start: Bool = true)
    {
        guard start else
        {
            stopObserving(supertask)
            return
        }
        
        //print("start observing supertask \(supertask.title.value ?? "untitled")")
        
        observe(supertask)
        {
            [weak self, weak supertask] change in
            
            guard let supertask = supertask else { return }
            
            self?.received(change, from: supertask)
        }
    }
    
    func received(_ edit: ListEdit, from supertask: Task)
    {
        //print("list <\(supertask.title.value ?? "untitled")> \(change)")
        
        switch edit
        {
        case .didInsert(let indexes):
            observeTasksListed(in: supertask, at: indexes)
            
        case .didRemove(let tasks, _):
            for task in tasks { observe(listedTask: task, start: false) }
            
        default: break
        }
        
        send(edit)
    }
    
    // MARK: - Observe Listed Tasks
    
    private func observeTasksListed(in supertask: Task,
                                    start: Bool = true)
    {
        let indexes = Array(0 ..< supertask.numberOfSubtasks)
        
        observeTasksListed(in: supertask, at: indexes, start: start)
    }
    
    private func observeTasksListed(in supertask: Task,
                                    at indexes: [Int],
                                    start: Bool = true)
    {
        for index in indexes
        {
            guard let task = supertask.subtask(at: index) else { continue }
            
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
                self?.supertask?.moveSubtaskToTopOfDoneList(from: taskIndex)
            }
        }
    }
    
    // MARK: - Listed Tasks
    
    func task(at index: Int) -> Task?
    {
        guard let supertask = supertask else
        {
            log(warning: "Tried to get task at \(index) from list without supertask.")
            return nil
        }
        
        return supertask.subtask(at: index)
    }
    
    var numberOfTasks: Int
    {
        guard let supertask = supertask else
        {
            log(warning: "Tried to get task number from list without supertask.")
            return 0
        }
        
        return supertask.numberOfSubtasks
    }
    
    // MARK: - Supertask
    
    private(set) weak var supertask: Task?
    {
        didSet
        {
            guard oldValue !== supertask else { return }
            
            didSwitchSupertask(from: oldValue, to: supertask)
        }
    }
    
    private func didSwitchSupertask(from old: Task?, to new: Task?)
    {
        //print("list changed supertask from \(old?.title.value ?? "untitled") to \(new?.title.value ?? "untitled")")
        
        title.observable = new?.title
        
        sendDidRemoveTasksOf(oldSupertask: old)
        sendDidInsertTasksOf(newSupertask: new)
    }
    
    private func sendDidRemoveTasksOf(oldSupertask old: Task?)
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
    
    private func sendDidInsertTasksOf(newSupertask new: Task?)
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

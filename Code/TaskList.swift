import SwiftObserver

class TaskList: Observable, Observer
{
    // MARK: - Configuration
    
    func set(supertask newSupertask: Task?)
    {
        guard newSupertask !== supertask else { return }
        
        observeTasks(with: supertask, start: false)
        observeTasks(with: newSupertask)
        
        supertask = newSupertask
    }
    
    deinit { stopAllObserving() }
    
    // MARK: - Observe Tasks
    
    private func observeTasks(with supertask: Task?, start: Bool = true)
    {
        guard let supertask = supertask else { return }
        
        observe(supertask: supertask, start: start)
        observeTasksListed(in: supertask, start: start)
    }
    
    private func observe(supertask: Task, start: Bool = true)
    {
        guard start else
        {
            stopObserving(supertask)
            return
        }
        
        observe(supertask)
        {
            [weak self] change in
            
            self?.received(change, from: supertask)
        }
    }
    
    private func received(_ change: Task.SubtaskChange,
                          from supertask: Task)
    {
        switch change
        {
        case .didInsert(let indexes):
            observeTasksListedIn(supertask, at: indexes)
            
        case .didRemove(let tasks, _):
            for task in tasks { observe(listedTask: task, start: false) }
            
        default: break
        }
        
        send(.didChangeListedTasks(change))
    }
    
    private func observeTasksListedIn(_ supertask: Task,
                                      at indexes: [Int],
                                      start: Bool = true)
    {
        for index in indexes
        {
            guard let task = supertask.subtask(at: index) else { continue }
            
            observe(listedTask: task, start: start)
        }
    }
    
    private func observeTasksListed(in supertask: Task, start: Bool = true)
    {
        for taskIndex in 0 ..< supertask.numberOfSubtasks
        {
            guard let task = supertask.subtask(at: taskIndex) else { continue }
            
            observe(listedTask: task, start: start)
        }
    }
    
    private func observe(listedTask task: Task, start: Bool = true)
    {
        guard start else
        {
            stopObserving(task.title)
            stopObserving(task.state)
            
            return
        }
        
        observe(task.title)
        {
            [weak self, weak task] titleUpdate in
            
            if let taskIndex = task?.indexInSupertask,
                titleUpdate.new != titleUpdate.old
            {
                self?.send(.didChangeListedTaskTitle(at: taskIndex))
            }
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
        return supertask?.subtask(at: index)
    }
    
    var numberOfTasks: Int
    {
        return supertask?.numberOfSubtasks ?? 0
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
        title.observable = new?.title
        
        var oldSubtasks = [Task]()
        var oldIndexes = [Int]()
        
        for i in 0 ..< (old?.numberOfSubtasks ?? 0)
        {
            if let oldSubtask = old?.subtask(at: i)
            {
                oldSubtasks.append(oldSubtask)
                oldIndexes.append(i)
            }
        }
        
        send(.didChangeListedTasks(.didRemove(subtasks: oldSubtasks,
                                              from: oldIndexes)))
        
        let newIndexes = Array(0 ..< (new?.numberOfSubtasks ?? 0))
        send(.didChangeListedTasks(.didInsert(at: newIndexes)))
    }
    
    let title = Var<String>().new().unwrap("")
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing
        case didChangeListedTaskTitle(at: Int)
        case didChangeListedTasks(Task.SubtaskChange)
    }
}

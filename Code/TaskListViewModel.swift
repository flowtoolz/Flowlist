import SwiftObserver
import SwiftyToolz

class TaskListViewModel: Observable, Observer
{
    // MARK: - Life Cycle
    
    deinit { stopAllObserving() }
    
    // MARK: - Edit Listing
    
    func groupSelectedTasks() -> Int?
    {
        guard let container = supertask,
            let group = container.groupSubtasks(at: selection.indexes)
        else
        {
            return nil
        }
        
        selection.add(group)
        
        observe(listedTask: group)
        
        return group.indexInSupertask
    }
    
    func add(_ task: Task, at index: Int?) -> Int?
    {
        guard let container = supertask else { return nil }
        
        var indexToInsert = index ?? 0
        
        if index == nil, let lastSelectedIndex = selection.indexes.last
        {
            indexToInsert = lastSelectedIndex + 1
        }
        
        _ = container.insert(task, at: indexToInsert)
        
        observe(listedTask: task)
        
        return indexToInsert
    }
    
    func deleteSelectedTasks() -> Bool
    {
        // delete
        let selectedIndexes = selection.indexes
        
        guard let firstSelectedIndex = selectedIndexes.first,
            let removedTasks = supertask?.removeSubtasks(at: selectedIndexes),
            !removedTasks.isEmpty
        else
        {
            return false
        }
        
        // stop observing
        for removedTask in removedTasks
        {
            stopObserving(removedTask)
        }
        
        // update selection
        if let newSelectedTask = task(at: max(firstSelectedIndex - 1, 0))
        {
            selection.add(newSelectedTask)
        }
        else
        {
            selection.removeAll()
        }
        
        return true
    }
    
    func moveSelectedTaskUp() -> Bool
    {
        guard let container = supertask,
            selection.count == 1,
            let selectedTask = selection.first,
            let selectedIndex = container.index(of: selectedTask)
        else
        {
            return false
        }

        return container.moveSubtask(from: selectedIndex, to: selectedIndex - 1)
    }
    
    func moveSelectedTaskDown() -> Bool
    {
        guard let container = supertask,
            selection.count == 1,
            let selectedTask = selection.first,
            let selectedIndex = container.index(of: selectedTask)
        else
        {
            return false
        }
        
        return container.moveSubtask(from: selectedIndex, to: selectedIndex + 1)
    }
    
    // MARK: - Edit State
    
    func checkOffFirstSelectedUncheckedTask()
    {
        // find first selected unchecked task
        var potentialTaskToCheck: Task?
        var potentialIndexToCheck: Int?
        
        for selectedIndex in selection.indexes
        {
            if let selectedTask = task(at: selectedIndex), !selectedTask.isDone
            {
                potentialTaskToCheck = selectedTask
                potentialIndexToCheck = selectedIndex
                break
            }
        }
        
        guard let taskToCheck = potentialTaskToCheck,
            let indexToCheck = potentialIndexToCheck
        else
        {
            return
        }
        
        // determine which task to select after the ckeck off
        var taskToSelect: Task?
        
        if selection.count == 1
        {
            taskToSelect = firstUncheckedTask(from: indexToCheck + 1)
        }
        
        taskToCheck.state <- .done
        
        if let taskToSelect = taskToSelect
        {
            selection.add(taskToSelect)
        }
        else if selection.count > 1
        {
            selection.remove(taskToCheck)
        }
    }
    
    private func firstUncheckedTask(from: Int = 0) -> Task?
    {
        for i in from ..< numberOfTasks
        {
            if let uncheckedTask = task(at: i), !uncheckedTask.isDone
            {
                return uncheckedTask
            }
        }
        
        return nil
    }
    
    // MARK: - Configuration
    
    func set(supertask newSupertask: Task?)
    {
        guard newSupertask !== supertask else { return }
        
        observeTasks(with: supertask, start: false)
        observeTasks(with: newSupertask)
        
        supertask = newSupertask
    }
    
    private func observeTasks(with supertask: Task?, start: Bool = true)
    {
        guard let supertask = supertask else { return }
        
        observe(supertask: supertask, start: start)
        observeTasksListed(in: supertask, start: start)
    }
    
    // MARK: - Observe Listed Tasks
    
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
                self?.send(.didChangeTaskTitle(at: taskIndex))
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
                self?.moveCheckedOffTask(at: taskIndex)
            }
        }
    }
    
    private func moveCheckedOffTask(at index: Int)
    {
        guard let supertask = supertask else { return }
        
        for i in (0 ..< supertask.numberOfSubtasks).reversed()
        {
            if let subtask = supertask.subtask(at: i), !subtask.isDone
            {
                _ = supertask.moveSubtask(from: index,
                                          to: i + (i < index ? 1 : 0))
                
                return
            }
        }
    }
    
    // MARK: - Observe Supertask
   
    private func observe(supertask: Task, start: Bool = true)
    {
        guard start else
        {
            stopObserving(supertask)
            return
        }
        
        observe(supertask)
        {
            [weak self, weak supertask] event in
            
            guard let supertask = supertask else { return }
            
            self?.didReceive(event, fromSupertask: supertask)
        }
    }
    
    private func didReceive(_ event: ListEditingEvent,
                            fromSupertask supertask: Task)
    {
        if event.itemsDidChange { selection.removeAll() }
        
        send(.didChangeTaskList(event))
    }
    
    // MARK: - Listed Tasks
    
    var numberOfTasks: Int
    {
        return supertask?.numberOfSubtasks ?? 0
    }
    
    func task(at index: Int) -> Task?
    {
        return supertask?.subtask(at: index)
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
        selection.supertask = new
        
        let oldIndexes = Array(0 ..< (old?.numberOfSubtasks ?? 0))
        send(.didChangeTaskList(.didRemoveItems(at: oldIndexes)))
        
        let newIndexes = Array(0 ..< (new?.numberOfSubtasks ?? 0))
        send(.didChangeTaskList(.didInsertItems(at: newIndexes)))
    }
    
    let title = Var<String>().new().unwrap("")
    
    // MARK: - Selection
    
    let selection = TaskSelection()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event: Equatable
    {
        case didNothing
        case didChangeTaskTitle(at: Int)
        case didChangeTaskList(ListEditingEvent)
    }
}

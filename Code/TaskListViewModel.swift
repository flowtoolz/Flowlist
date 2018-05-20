import SwiftObserver
import SwiftyToolz

class TaskListViewModel: Observable, Observer
{
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
    
    deinit { stopAllObserving() }
    
    // MARK: - Selection Dependent Editing
    
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
    
    func moveSelectedTask(_ positions: Int) -> Bool
    {
        guard positions != 0,
            let supertask = supertask,
            selection.count == 1,
            let selectedTask = selection.first,
            let selectedIndex = supertask.index(of: selectedTask)
        else
        {
            return false
        }

        return supertask.moveSubtask(from: selectedIndex,
                                     to: selectedIndex + positions)
    }
    
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
            let indexToCheck = potentialIndexToCheck else { return }
        
        // determine which task to select after the ckeck off
        var taskToSelect: Task?
        
        if selection.count == 1
        {
            let unchecked = supertask?.indexOfFirstUncheckedSubtask(from: indexToCheck + 1)
            
            taskToSelect = supertask?.subtask(at: unchecked)
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
    
    // MARK: - Listed Tasks
    
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
                self?.supertask?.moveSubtaskToTopOfDoneList(from: taskIndex)
            }
        }
    }
    
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
        selection.supertask = new
        
        let oldIndexes = Array(0 ..< (old?.numberOfSubtasks ?? 0))
        send(.didChangeTaskList(.didRemoveItems(at: oldIndexes)))
        
        let newIndexes = Array(0 ..< (new?.numberOfSubtasks ?? 0))
        send(.didChangeTaskList(.didInsertItems(at: newIndexes)))
    }
    
    let title = Var<String>().new().unwrap("")
    
    private func observe(supertask: Task, start: Bool = true)
    {
        guard start else
        {
            stopObserving(supertask)
            return
        }
        
        observe(supertask)
        {
            [weak self] event in
            
            self?.send(.didChangeTaskList(event))
        }
    }
    
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

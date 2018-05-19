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
    
    // MARK: - Listed Tasks
    
    var numberOfTasks: Int
    {
        return supertask?.numberOfSubtasks ?? 0
    }
    
    func task(at index: Int) -> Task?
    {
        return supertask?.subtask(at: index)
    }
    
    // MARK: - Configuration
    
    func set(supertask newSupertask: Task?)
    {
        guard newSupertask !== supertask else { return }
        
        stopObservingTasks()
        
        if let newSupertask = newSupertask
        {
            observe(supertask: newSupertask)
            observeTasksListed(in: newSupertask)
        }
        
        supertask = newSupertask
    }
    
    private func stopObservingTasks()
    {
        guard let supertask = supertask else { return }
        
        stopObserving(supertask)
        stopObserving(supertask.title)
        
        for taskIndex in 0 ..< supertask.numberOfSubtasks
        {
            guard let task = supertask.subtask(at: taskIndex) else { continue }
            
            stopObserving(task)
            stopObserving(task.title)
            stopObserving(task.state)
        }
    }
    
    // MARK: - Observe Supertask
   
    private func observe(supertask: Task)
    {
        observe(supertask)
        {
            [weak self, weak supertask] event in
            
            guard let supertask = supertask else { return }
            
            self?.didReceive(event, fromSupertask: supertask)
        }
        
        observe(supertask.title)
        {
            [weak self] _ in
            
            self?.send(.didChangeSupertaskTitle)
        }
    }
    
    private func didReceive(_ event: ListEditingEvent,
                            fromSupertask supertask: Task)
    {
        switch (event)
        {
        case .didMoveItem(let from, let to):
            self.task(supertask, didMoveSubtaskFrom: from, to: to)
            
        case .didInsertItem(let index):
            send(.didChangeTaskList(.didInsertItem(at: index)))
            
        case .didRemoveItems(let indexes):
            selection.removeTasks(at: indexes)
            send(.didChangeTaskList(.didRemoveItems(at: indexes)))
            
        default: break
        }
    }
    
    // MARK: - Observe Listed Tasks
    
    private func observeTasksListed(in supertask: Task)
    {
        for taskIndex in 0 ..< supertask.numberOfSubtasks
        {
            guard let task = supertask.subtask(at: taskIndex) else { continue }
            
            observe(listedTask: task)
        }
    }
    
    private func observe(listedTask task: Task)
    {
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
                stateUpdate.new != stateUpdate.old
            {
                self?.taskDidChangeState(task)
            }
        }
    }
    
    // MARK: - React to Data Changes
    
    private func taskDidChangeState(_ task: Task)
    {
        guard let taskIndex = task.indexInSupertask else { return }
        
        if task.isDone { moveCheckedOffTask(at: taskIndex) }
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
    
    private func task(_ task: Task, didMoveSubtaskFrom from: Int, to: Int)
    {
        guard supertask === task else { return }
        
        send(.didChangeTaskList(.didMoveItem(from: from, to: to)))
    }
    
    // MARK: - Supertask
    
    var title: String
    {
        return supertask?.title.value ?? "untitled"
    }
    
    private(set) weak var supertask: Task?
    {
        didSet
        {
            selection.supertask = supertask
            send(.didChangeSupertask)
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
        case didChangeSupertask
        case didChangeSupertaskTitle
    }
}

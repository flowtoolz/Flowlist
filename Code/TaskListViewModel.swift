import SwiftObserver
import SwiftyToolz

class TaskListViewModel: Observable, Observer
{
    // MARK: - List of Tasks

    var numberOfTasks: Int { return container?.numberOfSubtasks ?? 0 }
    
    func task(at index: Int) -> Task?
    {
        return container?.subtask(at: index)
    }
    
    func groupSelectedTasks() -> Int?
    {
        guard let container = container,
            let group = container.groupSubtasks(at: selectedIndexesSorted)
        else
        {
            return nil
        }
        
        selectedTasks = [group.hash : group]
        
        observe(task: group)
        
        return group.indexInSupertask
    }
    
    func add(_ task: Task, at index: Int?) -> Int?
    {
        guard let container = container else { return nil }
        
        var indexToInsert = index ?? 0
        
        if index == nil, let lastSelectedIndex = selectedIndexesSorted.last
        {
            indexToInsert = lastSelectedIndex + 1
        }
        
        _ = container.insert(task, at: indexToInsert)
        
        observe(task: task)
        
        return indexToInsert
    }
    
    func deleteSelectedTasks() -> Bool
    {
        // delete
        let selectedIndexes = selectedIndexesSorted
        
        guard let firstSelectedIndex = selectedIndexes.first,
            let removedTasks = container?.removeSubtasks(at: selectedIndexes),
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
            selectedTasks = [newSelectedTask.hash : newSelectedTask]
        }
        else
        {
            selectedTasks.removeAll()
        }
        
        return true
    }
    
    // FIXME: split this for insertion and removal
    func taskDidChangeSubtasks(sendingTask: Task,
                               event: Task.Event)
    {
        guard let container = container else
        {
            selectedTasks.removeAll()
            delegate?.didChangeListContainer()
            return
        }
        
        if container === sendingTask
        {
            switch(event)
            {
            case .didRemoveSubtasks(let indexes):
                unselectSubtasks(at: indexes)
                delegate?.didDeleteSubtasks(at: indexes)
            case .didInsertSubtask(let index):
                delegate?.didInsertSubtask(at: index)
            default: break
            }
        }
        else if container === sendingTask.supertask
        {
            if let index = container.index(of: sendingTask),
                sendingTask.numberOfSubtasks < 2
            {
                delegate?.didChangeSubtasksOfSubtask(at: index)
            }
        }
    }
    
    // MARK: - Move Selected Task
    
    func moveSelectedTaskUp() -> Bool
    {
        guard let container = container,
            selectedTasks.count == 1,
            let selectedTask = selectedTasks.values.first,
            let selectedIndex = container.index(of: selectedTask)
        else
        {
            return false
        }

        return container.moveSubtask(from: selectedIndex, to: selectedIndex - 1)
    }
    
    func moveSelectedTaskDown() -> Bool
    {
        guard let container = container,
            selectedTasks.count == 1,
            let selectedTask = selectedTasks.values.first,
            let selectedIndex = container.index(of: selectedTask)
        else
        {
            return false
        }
        
        return container.moveSubtask(from: selectedIndex, to: selectedIndex + 1)
    }
    
    func taskDidMoveSubtask(sender: Task?, from: Int, to: Int)
    {
        guard let sendingTask = sender,
            container === sendingTask
        else
        {
            return
        }
        
        delegate?.didMoveSubtask(from: from, to: to)
    }
    
    // MARK: - Task Data
    
    func taskDidChangeTitle(sender: Any)
    {
        guard container != nil,
            let updatedTask = sender as? Task,
            let indexOfUpdatedTask = updatedTask.indexInSupertask
        else
        {
            return
        }
        
        if updatedTask.supertask === container
        {
            delegate?.didChangeTitleOfSubtask(at: indexOfUpdatedTask)
        }
        else if updatedTask === container
        {
            delegate?.didChangeListContainerTitle()
        }
    }
    
    func checkOffFirstSelectedUncheckedTask()
    {
        // find first selected unchecked task
        var potentialTaskToCheck: Task?
        var potentialIndexToCheck: Int?
        
        for selectedIndex in selectedIndexesSorted
        {
            if let selectedTask = task(at: selectedIndex),
                selectedTask.state != .done
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
        
        if selectedTasks.count == 1
        {
            taskToSelect = firstUncheckedTask(from: indexToCheck + 1)
        }
        
        taskToCheck.state = .done
        
        if let taskToSelect = taskToSelect
        {
            selectedTasks = [taskToSelect.hash : taskToSelect]
        }
        else if selectedTasks.count > 1
        {
            selectedTasks[taskToCheck.hash] = nil
        }
    }
    
    private func firstUncheckedTask(from: Int = 0) -> Task?
    {
        for i in from ..< numberOfTasks
        {
            if let uncheckedTask = task(at: i), uncheckedTask.state != .done
            {
                return uncheckedTask
            }
        }
        
        return nil
    }
    
    func taskDidChangeState(sender: Any)
    {
        guard container != nil,
            let updatedTask = sender as? Task,
            updatedTask.supertask === container,
            let indexOfUpdatedTask = updatedTask.indexInSupertask
        else
        {
            return
        }
        
        delegate?.didChangeStateOfSubtask(at: indexOfUpdatedTask)
        
        if updatedTask.state == .done
        {
            taskAtIndexWasCheckedOff(indexOfUpdatedTask)
        }
    }
    
    private func taskAtIndexWasCheckedOff(_ index: Int)
    {
        guard let container = container else
        {
            return
        }
        
        for i in (0 ..< container.numberOfSubtasks).reversed()
        {
            if let subtask = container.subtask(at: i),
                subtask.state != .done
            {
                _ = container.moveSubtask(from: index, to: i + (i < index ? 1 : 0))
                
                return
            }
        }
    }
    
    // MARK: - Selection
    
    func unselectSubtasks(at indexes: [Int])
    {
        var newSelection = selectedTasks
        
        for index in indexes
        {
            if let task = task(at: index)
            {
                newSelection[task.hash] = nil
            }
        }
        
        selectedTasks = newSelection
    }
    
    func selectSubtasks(at indexes: [Int])
    {
        var newSelection = [HashValue : Task]()
        
        for index in indexes
        {
            if let task = task(at: index)
            {
                newSelection[task.hash] = task
            }
        }
        
        selectedTasks = newSelection
    }
    
    private func validateSelection()
    {
        guard let container = container else
        {
            if selectedTasks.count > 0
            {
                print("warning: task list has no container but these selections: \(selectedTasks.description)")
                
                selectedTasks.removeAll()
            }
            
            return
        }
        
        for selectedTask in selectedTasks.values
        {
            if container.index(of: selectedTask) == nil
            {
                print("warning: subtask is selected but not in the container. will be unselected: \(selectedTask.description)")
                selectedTasks[selectedTask.hash] = nil
            }
        }
    }
    
    var selectedIndexesSorted: [Int]
    {
        var result = [Int]()
        
        for index in 0 ..< numberOfTasks
        {
            if let task = task(at: index),
                selectedTasks[task.hash] != nil
            {
                result.append(index)
            }
        }
        
        return result
    }
    
    var selectedTasks = [HashValue : Task]()
    {
        didSet
        {
            if Set(oldValue.keys) != Set(selectedTasks.keys)
            {
                //print("selection changed: \(selectedIndexes.description)")
                validateSelection()
                send(.didChangeSelection)
            }
        }
    }
    
    // MARK: - Container Task
    
    var title: String
    {
        return container?.title ?? "untitled"
    }
    
    weak var container: Task?
    {
        didSet
        {
            guard oldValue !== container else { return }
            
            if let container = container
            {
                observe(task: container)
            }
            else
            {
                selectedTasks = [:]
            }
            
            if let oldValue = oldValue
            {
                stopObserving(oldValue)
            }
            
            delegate?.didChangeListContainer()
        }
    }
    
    weak var delegate: TaskListDelegate?
    
    // MARK: Observing a Task
    
    private func observe(task: Task)
    {
        observe(task)
        {
            [weak self, weak task] event in
            
            guard let task = task else { return }
            
            self?.didReceive(event: event, from: task)
        }
    }
    
    private func didReceive(event: Task.Event, from task: Task)
    {
        switch (event)
        {
        case .didNothing:
            break
        case .didChangeState:
            taskDidChangeState(sender: task)
        case .didChangeTitle:
            taskDidChangeTitle(sender: task)
        case .didMoveSubtask(let from, let to):
            taskDidMoveSubtask(sender: task, from: from, to: to)
        case .didInsertSubtask:
            taskDidChangeSubtasks(sendingTask: task, event: event)
        case .didRemoveSubtasks:
            taskDidChangeSubtasks(sendingTask: task, event: event)
        }
    }
    
    // MARK: Observable
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing
        case didChangeSelection
    }
}

extension Task
{
    var hash: HashValue { return SwiftyToolz.hash(self) }
}

// MARK: - Task List Delegate

protocol TaskListDelegate: AnyObject
{
    func didChangeSubtasksOfSubtask(at index: Int)
    func didChangeStateOfSubtask(at index: Int)
    func didChangeTitleOfSubtask(at index: Int)
    
    func didChangeListContainer()
    func didChangeListContainerTitle()
    func didInsertSubtask(at index: Int)
    func didDeleteSubtasks(at indexes: [Int])
    func didMoveSubtask(from: Int, to: Int)
}

import SwiftObserver
import SwiftyToolz

class TaskListViewModel: Observable, Observer
{
    // MARK: - List of Tasks

    var numberOfTasks: Int { return supertask?.numberOfSubtasks ?? 0 }
    
    func task(at index: Int) -> Task?
    {
        return supertask?.subtask(at: index)
    }
    
    func groupSelectedTasks() -> Int?
    {
        guard let container = supertask,
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
        guard let container = supertask else { return nil }
        
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
            selectedTasks = [newSelectedTask.hash : newSelectedTask]
        }
        else
        {
            selectedTasks.removeAll()
        }
        
        return true
    }
    
    // MARK: - Move Selected Task
    
    func moveSelectedTaskUp() -> Bool
    {
        guard let container = supertask,
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
        guard let container = supertask,
            selectedTasks.count == 1,
            let selectedTask = selectedTasks.values.first,
            let selectedIndex = container.index(of: selectedTask)
        else
        {
            return false
        }
        
        return container.moveSubtask(from: selectedIndex, to: selectedIndex + 1)
    }
    
    
    
    // MARK: - Task Data
    
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
        guard let container = supertask else
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
    
    // MARK: - Being Observed
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event
    {
        case didNothing
        case didChangeSelection
    }
    
    // MARK: - Supertask
    
    var title: String { return supertask?.title ?? "untitled" }
    
    weak var supertask: Task?
    {
        didSet
        {
            if oldValue !== supertask { supertaskDidChange() }
        }
    }
    
    private func supertaskDidChange()
    {
        resetObservations()
        selectedTasks = [:]
        delegate?.didChangeListContainer()
    }
    
    // MARK: - Observations
    
    private func resetObservations()
    {
        stopAllObserving()
        
        guard let supertask = supertask else { return }
        
        observe(task: supertask)
        
        for index in 0 ..< supertask.numberOfSubtasks
        {
            if let subtask = supertask.subtask(at: index)
            {
                observe(task: subtask)
            }
        }
    }
    
    private func observe(task: Task)
    {
        observe(task)
        {
            [weak self, weak task] event in
            
            guard let task = task else { return }
            
            self?.didReceive(event, from: task)
        }
    }
    
    private func didReceive(_ event: Task.Event, from task: Task)
    {
        switch (event)
        {
        case .didNothing:
            break
            
        case .didChangeState:
            taskDidChangeState(task)
            
        case .didChangeTitle:
            taskDidChangeTitle(task)
            
        case .didMoveSubtask(let from, let to):
            self.task(task, didMoveSubtaskFrom: from, to: to)
            
        case .didInsertSubtask(let index):
            self.task(task, didInsertSubtaskAt: index)
            
        case .didRemoveSubtasks(let indexes):
            self.task(task, didRemoveSubtasksAt: indexes)
        }
    }
    
    // MARK: - React to State Change
    
    private func taskDidChangeState(_ task: Task)
    {
        guard supertask != nil,
            task.supertask === supertask,
            let indexOfUpdatedTask = task.indexInSupertask
        else
        {
            return
        }
        
        delegate?.didChangeStateOfSubtask(at: indexOfUpdatedTask)
        
        if task.state == .done
        {
            taskAtIndexWasCheckedOff(indexOfUpdatedTask)
        }
    }
    
    private func taskAtIndexWasCheckedOff(_ index: Int)
    {
        guard let supertask = supertask else { return }
        
        for i in (0 ..< supertask.numberOfSubtasks).reversed()
        {
            if let subtask = supertask.subtask(at: i),
                subtask.state != .done
            {
                _ = supertask.moveSubtask(from: index,
                                          to: i + (i < index ? 1 : 0))
                
                return
            }
        }
    }
    
    // MARK: - React to Title Change
    
    private func taskDidChangeTitle(_ task: Task)
    {
        guard supertask != nil, let taskIndex = task.indexInSupertask else
        {
            return
        }
        
        if task.supertask === supertask
        {
            delegate?.didChangeTitleOfSubtask(at: taskIndex)
        }
        else if task === supertask
        {
            delegate?.didChangeListContainerTitle()
        }
    }
    
    // MARK: - React to Subtask Move
    
    private func task(_ task: Task, didMoveSubtaskFrom from: Int, to: Int)
    {
        guard supertask === task else { return }
        
        delegate?.didMoveSubtask(from: from, to: to)
    }
    
    // MARK: - React to Insertion
    
    private func task(_ task: Task, didInsertSubtaskAt index: Int)
    {
        // FIXME: what is this? an error edge case??
        guard let supertask = supertask else
        {
            selectedTasks.removeAll()
            delegate?.didChangeListContainer()
            return
        }
        
        if supertask === task
        {
            delegate?.didInsertSubtask(at: index)
        }
        else if supertask === task.supertask
        {
            if let index = supertask.index(of: task)
            {
                delegate?.subtasksChangedInTask(at: index)
            }
        }
    }
    
    // MARK: - React to Removal
    
    private func task(_ task: Task, didRemoveSubtasksAt indexes: [Int])
    {
        // FIXME: what is this? an error edge case??
        guard let supertask = supertask else
        {
            selectedTasks.removeAll()
            delegate?.didChangeListContainer()
            return
        }
        
        // update from supertask
        if supertask === task
        {
            unselectSubtasks(at: indexes)
            delegate?.didDeleteSubtasks(at: indexes)
        }
        // update from regular task
        else if supertask === task.supertask
        {
            if let index = task.indexInSupertask
            {
                delegate?.subtasksChangedInTask(at: index)
            }
        }
    }
    
    // MARK: - Delegate
    
    weak var delegate: TaskListDelegate?
}

// MARK: -

extension Task
{
    var hash: HashValue { return SwiftyToolz.hash(self) }
}

// MARK: -

protocol TaskListDelegate: AnyObject
{
    func subtasksChangedInTask(at index: Int)
    func didChangeStateOfSubtask(at index: Int)
    func didChangeTitleOfSubtask(at index: Int)
    
    func didChangeListContainer()
    func didChangeListContainerTitle()
    
    func didInsertSubtask(at index: Int)
    func didDeleteSubtasks(at indexes: [Int])
    func didMoveSubtask(from: Int, to: Int)
}

import SwiftObserver

class TaskList: Observable, Observer
{
    // MARK: - List of Tasks

    var tasks: [Task]
    {
        return container?.subtasks ?? []
    }
    
    func task(at index: Int) -> Task?
    {
        return container?.subtask(at: index)
    }
    
    func groupSelectedTasks(as group: Task) -> Int?
    {
        guard let container = container,
            let groupIndex = container.groupTasks(at: selectedIndexesSorted,
                                                  as: group)
        else
        {
            return nil
        }
        
        selectedTasksByUuid = [group.uuid : group]
        
        observe(task: group)
        
        return groupIndex
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
            let removedTasks = container?.deleteSubtasks(at: selectedIndexes),
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
            selectedTasksByUuid = [newSelectedTask.uuid : newSelectedTask]
        }
        else
        {
            selectedTasksByUuid.removeAll()
        }
        
        return true
    }
    
    func taskDidChangeSubtasks(sendingTask: Task,
                               method: Task.Event.Method,
                               indexes: [Int]?)
    {
        guard let container = container else
        {
            selectedTasksByUuid.removeAll()
            delegate?.didChangeListContainer()
            return
        }
        
        if container === sendingTask
        {
            switch(method)
            {
            case .delete:
                if let indexes = indexes
                {
                    unselectSubtasks(at: indexes)
                    delegate?.didDeleteSubtasks(at: indexes)
                }
               
            case .insert:
                if let index = indexes?.first
                {
                    delegate?.didInsertSubtask(at: index)
                }
            }
        }
        else if container === sendingTask.supertask
        {
            if let index = container.index(of: sendingTask),
                sendingTask.subtasks.count < 2
            {
                delegate?.didChangeSubtasksOfSubtask(at: index)
            }
        }
    }
    
    // MARK: - Move Selected Task
    
    func moveSelectedTaskUp() -> Bool
    {
        guard let container = container,
            selectedTasksByUuid.count == 1,
            let selectedTask = selectedTasksByUuid.values.first,
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
            selectedTasksByUuid.count == 1,
            let selectedTask = selectedTasksByUuid.values.first,
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
            let indexOfUpdatedTask = updatedTask.indexInContainer
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
        
        if selectedTasksByUuid.count == 1
        {
            taskToSelect = firstUncheckedTask(from: indexToCheck + 1)
        }
        
        taskToCheck.state = .done
        
        if let taskToSelect = taskToSelect
        {
            selectedTasksByUuid = [taskToSelect.uuid : taskToSelect]
        }
        else if selectedTasksByUuid.count > 1
        {
            selectedTasksByUuid[taskToCheck.uuid] = nil
        }
    }
    
    private func firstUncheckedTask(from: Int = 0) -> Task?
    {
        for i in from ..< tasks.count
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
            let indexOfUpdatedTask = updatedTask.indexInContainer
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
        
        for i in (0 ..< container.subtasks.count).reversed()
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
        var newSelection = selectedTasksByUuid
        
        for index in indexes
        {
            if let task = task(at: index)
            {
                newSelection[task.uuid] = nil
            }
        }
        
        selectedTasksByUuid = newSelection
    }
    
    func selectSubtasks(at indexes: [Int])
    {
        var newSelection = [String : Task]()
        
        for index in indexes
        {
            if let task = task(at: index)
            {
                newSelection[task.uuid] = task
            }
        }
        
        selectedTasksByUuid = newSelection
    }
    
    private func validateSelection()
    {
        guard let container = container else
        {
            if selectedTasksByUuid.count > 0
            {
                print("warning: task list has no container but these selections: \(selectedTasksByUuid.description)")
                
                selectedTasksByUuid.removeAll()
            }
            
            return
        }
        
        for selectedTask in selectedTasksByUuid.values
        {
            if container.index(of: selectedTask) == nil
            {
                print("warning: subtask is selected but not in the container. will be unselected: \(selectedTask.description)")
                selectedTasksByUuid[selectedTask.uuid] = nil
            }
        }
    }
    
    var selectedIndexesSorted: [Int]
    {
        var result = [Int]()
        
        for index in 0 ..< tasks.count
        {
            if let task = task(at: index),
                selectedTasksByUuid[task.uuid] != nil
            {
                result.append(index)
            }
        }
        
        return result
    }
    
    var selectedTasksByUuid = [String : Task]()
    {
        didSet
        {
            if Set(oldValue.keys) != Set(selectedTasksByUuid.keys)
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
    
    func goToSuperContainer() -> Bool
    {
        //print("list of container \(container?.title ?? "untitled") wants to go to super container")
        
        guard let myContainer = container else
        {
            print("cannot go to super container because my container is nil")
            return false
        }
        
        guard let superContainer = myContainer.supertask else
        {
            //print("cannot go to super container because it is nil")
            return false
        }
        
        container = superContainer
        
        selectedTasksByUuid = [myContainer.uuid : myContainer]
        
        return true
    }
    
    func goToSelectedTask() -> Bool
    {
        guard selectedTasksByUuid.count == 1,
            let selectedTask = selectedTasksByUuid.values.first,
            selectedTask.isContainer
        else
        {
            return false
        }
        
        container = selectedTask
        
        if let firstTask = task(at: 0)
        {
            selectedTasksByUuid = [firstTask.uuid : firstTask]
        }
        else
        {
            selectedTasksByUuid = [:]
        }
        
        return true
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
                selectedTasksByUuid = [:]
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
        case .didChangeSubtasks(let method, let indexes):
            taskDidChangeSubtasks(sendingTask: task,
                                  method: method,
                                  indexes: indexes)
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

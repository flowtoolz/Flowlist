//
//  TaskList.swift
//  TodayList
//
//  Created by Sebastian on 15/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Flowtoolz

class TaskList: Sender, Subscriber
{
    init()
    {
        subscribe(to: Task.didChangeTitle, action: taskDidChangeTitle)
        subscribe(to: Task.didChangeState, action: taskDidChangeState)
        subscribe(to: Task.didChangeSubtasks, action: taskDidChangeSubtasks)
        subscribe(to: Task.didMoveSubtask, action: taskDidMoveSubtask)
    }
    
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
        
        return indexToInsert
    }
    
    func deleteSelectedTasks() -> Bool
    {
        let selectedIndexes = selectedIndexesSorted
        
        guard let firstSelectedIndex = selectedIndexes.first,
            container?.deleteSubtasks(at: selectedIndexes) ?? false
        else
        {
            return false
        }
        
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
    
    func taskDidChangeSubtasks(sender: Any, parameters: [String : Any]?)
    {
        guard container != nil else
        {
            selectedTasksByUuid.removeAll()
            delegate?.didChangeListContainer()
            return
        }
        
        guard let sendingTask = sender as? Task,
            container === sendingTask,
            let method = parameters?["method"] as? String
        else
        {
            return
        }
        
        if method == "delete", let indexes = parameters?["indexes"] as? [Int]
        {
            unselectSubtasks(at: indexes)
            
            delegate?.didDeleteSubtasks(at: indexes)
        }
        else if method == "insert", let index = parameters?["index"] as? Int
        {
            delegate?.didInsertSubtask(at: index)
        }
        else
        {
            print("Warning: TaskList received notification \(Task.didChangeSubtasks) with unknown change method \(method) or parameters \(parameters.debugDescription)")
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
    
    func taskDidMoveSubtask(sender: Any, parameters: [String : Any]?)
    {
        guard let sendingTask = sender as? Task,
            container === sendingTask,
            let from = parameters?["from"] as? Int,
            let to = parameters?["to"] as? Int
        else
        {
            return
        }
        
        // print("task \(sendingTask.description) did move subtask: \(parameters.debugDescription)")
        
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
        
        if updatedTask.container === container
        {
            delegate?.didChangeTitleOfSubtask(at: indexOfUpdatedTask)
        }
        else if updatedTask === container
        {
            delegate?.didChangeListContainerTitle()
        }
    }
    
    func taskDidChangeState(sender: Any)
    {
        guard container != nil,
            let updatedTask = sender as? Task,
            updatedTask.container === container,
            let indexOfUpdatedTask = updatedTask.indexInContainer
        else
        {
            return
        }
        
        delegate?.didChangeStateOfSubtask(at: indexOfUpdatedTask)
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
                send(TaskList.didChangeSelection)
            }
        }
    }
    
    static let didChangeSelection = "TaskListDidChangeSelection"
    
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
        
        guard let superContainer = myContainer.container else
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
            if oldValue !== container
            {
                if container == nil
                {
                    selectedTasksByUuid = [:]
                }
                
                delegate?.didChangeListContainer()
            }
        }
    }
    
    var delegate: TaskListDelegate?
}

// MARK: - Task List Delegate

protocol TaskListDelegate
{
    func didChangeStateOfSubtask(at index: Int)
    func didChangeTitleOfSubtask(at index: Int)
    func didChangeListContainer()
    func didChangeListContainerTitle()
    func didInsertSubtask(at index: Int)
    func didDeleteSubtasks(at indexes: [Int])
    func didMoveSubtask(from: Int, to: Int)
}

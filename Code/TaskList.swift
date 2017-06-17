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
    }
    
    // MARK: - Listen to Changes (manage selection and notify delegate)
    
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
    
    func taskDidChangeSubtasks(sender: Any, parameters: [String : Any]?)
    {
        guard container != nil else
        {
            selectedIndexes = []
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
            updateSelectionAfterDeletingTasks(at: indexes)
            
            delegate?.didDeleteSubtasks(at: indexes)
        }
        else if method == "insert", let index = parameters?["index"] as? Int
        {
            updateSelectionAfterInsertingTask(at: index)
            
            delegate?.didInsertSubtask(at: index)
        }
        else
        {
            print("Warning: TaskList received notification \(Task.didChangeSubtasks) with unknown change method \(method) or parameters \(parameters.debugDescription)")
        }
    }
    
    var delegate: TaskListDelegate?
    
    // MARK: - Edit
    
    
    // FIXME: do most of this in Task class
    func groupSelectedTasks(as group: Task) -> Int?
    {
        guard let groupIndex = selectedIndexes.min() else
        {
            return nil
        }
        
        for deletionIndex in selectedIndexes
        {
            if let removedTask = container?.subtask(at: deletionIndex)
            {
                _ = group.insert(removedTask, at: group.subtasks.count)
            }
        }
        
        _ = container?.deleteSubtasks(at: selectedIndexes)
        
        _ = container?.insert(group, at: groupIndex)

        selectedIndexes = [groupIndex]
        
        return groupIndex
    }
    
    func add(_ task: Task, at index: Int?) -> Int
    {
        var indexToInsert = index ?? 0
        
        if index == nil, let lastSelectedIndex = selectedIndexes.max()
        {
            indexToInsert = lastSelectedIndex + 1
        }
        
        _ = container?.insert(task, at: indexToInsert)
        
        return indexToInsert
    }
    
    func deleteSelectedTasks() -> Bool
    {
        let firstSelectedIndex = selectedIndexes.min() ?? 0
        
        guard container?.deleteSubtasks(at: selectedIndexes) ?? false else
        {
            return false
        }
        
        selectedIndexes = numberOfTasks > 0 ? [max(firstSelectedIndex - 1, 0)] : []
        
        return true
    }
    
    // MARK: - Navigate
    
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
        
        guard let index = myContainer.indexInContainer else
        {
            print("cannot go to super container because index of my container in super container returned nil")
            return false
        }
        
        container = superContainer
        
        selectedIndexes = [index]
        
        return true
    }
    
    func goToSelectedTask() -> Bool
    {
        guard selectedIndexes.count == 1,
            let selectedIndex = selectedIndexes.first,
            let task = task(at: selectedIndex),
            task.isContainer
        else
        {
            return false
        }
        
        container = task
        
        selectedIndexes = [0]
        
        return true
    }
    
    // MARK: - Select
    
    private func updateSelectionAfterDeletingTasks(at indexes: [Int])
    {
        for deletedIndex in indexes.sorted(by: >)
        {
            updateSelectionAfterDeletingTask(at: deletedIndex)
        }
    }
    
    private func updateSelectionAfterDeletingTask(at indexOfDeletion: Int)
    {
        // remove deleted task from selections
        if let indexOfDeletionInSelections = selectedIndexes.index(of: indexOfDeletion)
        {
            selectedIndexes.remove(at: indexOfDeletionInSelections)
        }
        
        // move selections below deleted task up 1 position
        for i in 0 ..< selectedIndexes.count
        {
            if selectedIndexes[i] > indexOfDeletion
            {
                selectedIndexes[i] -= 1
            }
        }
    }
    
    private func updateSelectionAfterInsertingTask(at indexOfInsertion: Int)
    {
        for i in 0 ..< selectedIndexes.count
        {
            if selectedIndexes[i] >= indexOfInsertion
            {
                selectedIndexes[i] += 1
            }
        }
    }
    
    var selectedIndexes = [Int]()
    {
        didSet
        {
            if oldValue != selectedIndexes
            {
                validateSelection()
                send(TaskList.didChangeSelection)
            }
        }
    }
    
    static let didChangeSelection = "TaskListDidChangeSelection"
    
    private func validateSelection()
    {
        if numberOfTasks == 0
        {
            if selectedIndexes.count > 0
            {
                print("warning: no subtasks in list. selections will be deleted: \(selectedIndexes)")
                selectedIndexes.removeAll()
            }
        }
        else
        {
            selectedIndexes.sort()
            
            while let lastIndex = selectedIndexes.last, lastIndex >= numberOfTasks
            {
                print("warning: subtask selection index \(lastIndex) is out of bounds and will be removed")
                _ = selectedIndexes.popLast()
            }
        }
    }
    
    // MARK: - Read
    
    var title: String
    {
        return container?.title ?? "untitled"
    }
    
    func task(at index: Int) -> Task?
    {
        return container?.subtask(at: index)
    }
    
    var numberOfTasks: Int
    {
        return container?.subtasks.count ?? 0
    }
    
    // MARK: - Container
    
    weak var container: Task?
    {
        didSet
        {
            if oldValue !== container
            {
                if container == nil
                {
                    selectedIndexes = []
                }
                
                delegate?.didChangeListContainer()
            }
        }
    }
}

protocol TaskListDelegate
{
    func didChangeStateOfSubtask(at index: Int)
    func didChangeTitleOfSubtask(at index: Int)
    func didChangeListContainer()
    func didChangeListContainerTitle()
    func didInsertSubtask(at index: Int)
    func didDeleteSubtasks(at indexes: [Int])
}

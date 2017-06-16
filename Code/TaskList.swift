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
        self.container = taskStore.root
        
        subscribe(to: TaskStore.didUpdateRoot)
        {
            self.container = taskStore.root
        }

        subscribe(to: Task.didChangeSubtasks, action: taskDidChangeSubtasks)
    }
    
    // MARK: - Forward Task Updates
    
    func taskDidChangeSubtasks(sender: Any, parameters: [String : Any]?)
    {
        guard let sendingTask = sender as? Task,
            container === sendingTask
        else
        {
            return
        }

        guard let indexes = parameters?["indexes"] as? [Int],
            let method = parameters?["method"] as? String
        else
        {
            return
        }
        
        print("TaskList \"\(container?.title ?? "Untitled")\" did \(method) subtask at indexes \(indexes.description)")
        
        if method == "delete"
        {
            delegate?.didDeleteSubtasks(at: indexes)
        }
        else if method == "insert"
        {
            delegate?.didInsertSubtasks(at: indexes)
        }
        else
        {
            print("Warning: TaskList received notification \(Task.didChangeSubtasks) with unknown change method \(method)")
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
        guard container?.deleteSubtasks(at: selectedIndexes) ?? false else
        {
            return false
        }
        
        let firstIndex = selectedIndexes.min() ?? 0
        
        selectedIndexes = numberOfTasks > 0 ? [max(firstIndex - 1, 0)] : []
        
        return true
    }
    
    // MARK: - Navigate
    
    func goToSuperContainer() -> Bool
    {
        guard let superContainer = container?.container,
            let index = container?.indexInContainer
        else
        {
            return false
        }
        
        container = superContainer
        
        selectedIndexes = [index]
        
        return true
    }
    
    func goToSelectedTask() -> Bool
    {
        guard selectedIndexes.count == 1,
            let task = task(at: selectedIndexes[0]),
            task.isContainer
            else
        {
            return false
        }
        
        container = task
        
        return true
    }
    
    // MARK: - Select
    
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
    
    func task(at index: Int) -> Task?
    {
        return container?.subtask(at: index)
    }
    
    var numberOfTasks: Int
    {
        return container?.subtasks.count ?? 0
    }

    var title: String
    {
        return container?.title ?? "untitled"
    }
    
    // MARK: - Container
    
    private weak var container: Task?
}

protocol TaskListDelegate
{
    func didInsertSubtasks(at indexes: [Int])
    func didDeleteSubtasks(at indexes: [Int])
}

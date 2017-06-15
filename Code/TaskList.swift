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
    }
    
    // MARK: - Edit
    
    func groupSelectedTasks(as group: Task) -> Int?
    {
        guard let groupIndex = selectedIndexes.min() else
        {
            return nil
        }
        
        var removedTasks = [Task]()
        var sortedIndexes = selectedIndexes.sorted { return $0 < $1 }
        
        while let lastIndex = sortedIndexes.popLast()
        {
            if let removedTask = container.task(at: lastIndex)
            {
                removedTasks.insert(removedTask, at: 0)
            
                container.deleteTask(at: lastIndex)
            }
        }
        
        container.insert(group, at: groupIndex)
        
        while let element = removedTasks.popLast()
        {
            group.insert(element, at: 0)
        }
        
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
        
        container.insert(task, at: indexToInsert)
        
        return indexToInsert
    }
    
    func deleteSelectedTasks() -> Bool
    {
        var sorted = selectedIndexes.sorted { return $0 < $1 }
        
        guard let firstIndex = sorted.first else
        {
            return false
        }
        
        while let lastIndex = sorted.popLast()
        {
            container.deleteTask(at: lastIndex)
        }
        
        selectedIndexes = numberOfTasks > 0 ? [max(firstIndex - 1, 0)] : []
        
        return true
    }
    
    // MARK: - Navigate
    
    func goToSuperContainer() -> Bool
    {
        guard let superContainer = container.container,
            let index = container.indexInContainer
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
                selectedIndexes.popLast()
            }
        }
    }
    
    // MARK: - Read
    
    func task(at index: Int) -> Task?
    {
        return container.task(at: index)
    }
    
    var numberOfTasks: Int
    {
        return container.subTasks.count
    }

    var title: String
    {
        return container.title ?? "Untitled"
    }
    
    // MARK: - Container
    
    private var container: Task
    {
        didSet
        {
            if oldValue !== container
            {
                send(TaskList.didUpdateContainer)
            }
        }
    }
    
    static let didUpdateContainer = "TaskListDidUpdateContainer"
}

//
//  TaskStore.swift
//  TodayList
//
//  Created by Sebastian on 13/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Flowtoolz

let taskStore = TaskStore()

class TaskStore: Sender
{
    fileprivate init()
    {
        listContainer = self.rootTask
    }
    
    // MARK: - Edit the List
    
    func groupSelectedTasks(as container: Task) -> Int?
    {
        guard let containerIndex = selectedIndexes.min() else
        {
            return nil
        }
        
        var removedTasks = [Task]()
        var sortedIndexes = selectedIndexes.sorted { return $0 < $1 }
        
        while let lastIndex = sortedIndexes.popLast()
        {
            if let removedTask = listContainer.elements?.remove(at: lastIndex)
            {
                removedTasks.insert(removedTask, at: 0)
            }
        }
        
        listContainer.insert(container, at: containerIndex)
        
        while let element = removedTasks.popLast()
        {
            container.insert(element, at: 0)
        }
        
        selectedIndexes = [containerIndex]
        
        return containerIndex
    }
    
    func add(_ task: Task, at index: Int?) -> Int
    {
        var indexToInsert = index ?? 0
        
        if index == nil, let lastSelectedIndex = selectedIndexes.max()
        {
            indexToInsert = lastSelectedIndex + 1
        }
        
        listContainer.insert(task, at: indexToInsert)
        
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
            listContainer.elements?.remove(at: lastIndex)
        }
        
        selectedIndexes = [max(firstIndex - 1, 0)]
        
        return true
    }
    
    // MARK: - Filter the List
    
    func filterBySuperContainer() -> Bool
    {
        guard let superContainer = listContainer.container,
            let index = listContainer.indexInContainer
        else
        {
            return false
        }
        
        listContainer = superContainer
        
        selectedIndexes = [index]
        
        return true
    }
    
    func filterBySelectedTask() -> Bool
    {
        guard selectedIndexes.count == 1,
            let task = task(at: selectedIndexes[0]),
            task.isContainer
        else
        {
            return false
        }
        
        listContainer = task
        
        return true
    }
    
    // MARK: - Task List and Selection
    
    var selectedIndexes = [Int]()
    {
        didSet
        {
            if oldValue != selectedIndexes
            {
                send(TaskStore.selectionDidChange)
            }
        }
    }
    
    static let selectionDidChange = "selectionDidChange"
    
    func task(at index: Int) -> Task?
    {
        return listContainer.task(at: index)
    }
    
    var list: [Task]
    {
        return listContainer.elements ?? []
    }

    func reset(with root: Task)
    {
        rootTask = root
        
        listContainer = root
    }
    
    private var listContainer: Task
    {
        didSet
        {
            if oldValue.uuid != listContainer.uuid
            {
                send(TaskStore.listContainerDidChange)
            }
        }
    }

    static let listContainerDidChange = "listContainerDidChange"
    
    var root: Task
    {
        return rootTask
    }
    
    private var rootTask = Task()
}

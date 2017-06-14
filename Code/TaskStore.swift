//
//  TaskStore.swift
//  TodayList
//
//  Created by Sebastian on 13/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

let taskStore = TaskStore()

class TaskStore
{
    fileprivate init() {}
    
    func groupListedTasks(at indexes: [Int], in newTask: Task)
    {
        var sorted = indexes.sorted { return $0 < $1 }
        
        guard let minIndex = sorted.first else
        {
            return
        }
        
        // remove tasks
        var removedTasks = [Task]()
        
        while let lastIndex = sorted.popLast()
        {
            if let removed = listedContainer.elements?.remove(at: lastIndex)
            {
                removedTasks.insert(removed, at: 0)
            }
        }
        
        // add container
        add(newTask, toListAt: minIndex)
        
        while let element = removedTasks.popLast()
        {
            newTask.insert(element, at: 0)
        }
    }
    
    func add(_ task: Task, toListAt index: Int)
    {
        listedContainer.insert(task, at: index)
        
        task.container = listedContainer
    }
    
    func deleteTasksFromList(at indexes: [Int])
    {
        var sorted = indexes.sorted { return $0 < $1 }
        
        while let lastIndex = sorted.popLast()
        {
            listedContainer.elements?.remove(at: lastIndex)
        }
    }
    
    var list: [Task]
    {
        return listedContainer.elements ?? []
    }
    
    func filterByTask(at index: Int) -> Bool
    {
        guard let task = listedContainer.task(at: index), task.isContainer else
        {
            return false
        }
        
        listedContainer = task
        
        return true
    }
    
    func indexOfListedContainerInItsContainer() -> Int?
    {
        return listedContainer.container?.elements?.index
        {
            element in
            
            return element.uuid == self.listedContainer.uuid
        }
    }
    
    func filterByContainerOfListedContainer() -> Bool
    {
        guard let superContainer = listedContainer.container else
        {
            return false
        }
        
        listedContainer = superContainer
        
        return true
    }
    
    func reset(with root: Task)
    {
        rootTask = root
        
        listedContainer = root
    }
    
    var root: Task
    {
        return rootTask
    }
    
    private lazy var listedContainer: Task = self.rootTask
    
    private var rootTask = Task()
}

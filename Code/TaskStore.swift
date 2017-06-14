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
    
    func deleteTasksFromList(at indexes: [Int])
    {
        var sorted = indexes.sorted { return $0 < $1 }
        
        while let lastIndex = sorted.popLast()
        {
            listedContainer.elements?.remove(at: lastIndex)
        }
    }
    
    func add(_ task: Task, toListAt index: Int)
    {
        listedContainer.insert(task, at: index)
        
        task.container = listedContainer
    }
    
    var list: [Task]
    {
        return listedContainer.elements ?? []
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

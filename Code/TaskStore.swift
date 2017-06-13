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
    
    func removeTasks(at indexes: [Int])
    {
        var sorted = indexes.sorted { return $0 < $1 }
        
        while let lastIndex = sorted.popLast()
        {
            tasks.remove(at: lastIndex)
        }
    }
    
    lazy var tasks: [Task] =
    {
        var tasks = [Task]()
        
        for i in 0 ... 20
        {
            let task = Task()
            
            task.title = "Task Title \(i)"
            
            tasks.append(task)
        }
        
        return tasks
    }()
}

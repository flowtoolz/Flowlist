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
    
    lazy var tasks: [Task] =
    {
        var tasks = [Task]()
        
        for i in 0 ... 50
        {
            let task = Task()
            
            task.title = "Task Title \(i)"
            
            tasks.append(task)
        }
        
        return tasks
    }()
}

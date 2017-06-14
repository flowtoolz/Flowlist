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
    
    var tasks = [Task]()
}

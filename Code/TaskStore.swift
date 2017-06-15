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
    fileprivate init() {}
    
    var root = Task()
    {
        didSet
        {
            root.title = "ROOT TASK"
            send(TaskStore.didUpdateRoot)
        }
    }
    
    static let didUpdateRoot = "TaskStoreDidUpdateRoot"
}

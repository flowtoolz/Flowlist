//
//  TaskListCoordinator.swift
//  Flowlist
//
//  Created by Sebastian on 16/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Flowtoolz

let listCoordinator = TaskListCoordinator()

class TaskListCoordinator
{
    fileprivate init() {}
    
    var lists = [TaskList(), TaskList(), TaskList(), TaskList(), TaskList()]
}

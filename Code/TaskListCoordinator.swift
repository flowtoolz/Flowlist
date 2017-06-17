//
//  TaskListCoordinator.swift
//  Flowlist
//
//  Created by Sebastian on 16/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Flowtoolz

let listCoordinator = TaskListCoordinator()

class TaskListCoordinator: Subscriber
{
    fileprivate init()
    {
        lists[0].container = store.root
        
        subscribe(to: TaskList.didChangeSelection, action: listChangedSelection)
    }
    
    private func listChangedSelection(sender: Any)
    {
        guard let index = lists.index(where: { $0 === sender as AnyObject }) else
        {
            print("Warning: TaskListCoordinator received notification from unknown TaskList.")
            return
        }
        
        //print("selection changed in list \(index): \(lists[index].selectedIndexes.description)")
        
        updateTaskList(at: index + 1)
    }
    
    private func updateTaskList(at index: Int)
    {
        guard index > 0, index < lists.count else
        {
            return
        }
        
        let slave = lists[index]
        let master = lists[index - 1]
        
        guard master.selectedIndexes.count == 1,
            let container = master.task(at: master.selectedIndexes[0]),
            container.isContainer
        else
        {
            slave.container = nil
            return
        }
        
        slave.container = container
    }
    
    var lists = [TaskList(), TaskList(), TaskList(), TaskList(), TaskList()]
}

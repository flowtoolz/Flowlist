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
        lists[2].container = store.root
        
        subscribe(to: TaskList.didChangeSelection, action: listChangedSelection)
    }
    
    func moveRight() -> TaskList
    {
        lists.remove(at: 0)
        
        let newList = TaskList()
        lists.append(newList)
        
        return newList
    }
    
    func moveLeft() -> TaskList
    {
        _ = lists.popLast()
        
        let newList = TaskList()
        
        lists.insert(newList, at: 0)
        
        return newList
    }
    
    func selectSlaveInMaster(at index: Int)
    {
        guard index >= 0, index + 1 < lists.count else
        {
            return
        }
        
        let master = lists[index]
        
        guard master.container?.isContainer ?? false else
        {
            return
        }
        
        let slave = lists[index + 1]
        
        if let slaveContainer = slave.container
        {
            master.selectedTasksByUuid = [slaveContainer.uuid : slaveContainer]
        }
    }
    
    private func listChangedSelection(sender: Any)
    {
        guard let index = lists.index(where: { $0 === sender as AnyObject }) else
        {
            print("Warning: TaskListCoordinator received notification from unknown TaskList.")
            return
        }
        
        setContainerOfSlave(at: index + 1)
    }
    
    func setContainerOfLastList()
    {
        guard lists.count > 0 else { return }
        
        setContainerOfSlave(at: lists.count - 1)
    }
    
    func setContainerOfSlave(at index: Int)
    {
        guard index > 0, index < lists.count else
        {
            return
        }
        
        let slave = lists[index]
        let master = lists[index - 1]
        
        guard master.selectedTasksByUuid.count == 1,
            let container = master.selectedTasksByUuid.values.first
        else
        {
            slave.container = nil
            return
        }
        
        slave.container = container
    }
    
    func setContainerOfMaster(at index: Int)
    {
        guard index >= 0, index < lists.count - 1 else
        {
            return
        }
        
        let master = lists[index]
        let slave = lists[index + 1]
        
        master.container = slave.container?.container
    }
    
    var lists = [TaskList(), TaskList(), TaskList(), TaskList(), TaskList()]
}

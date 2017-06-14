//
//  TaskStorePersister.swift
//  TodayList
//
//  Created by Sebastian on 14/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Foundation
import Flowtoolz

extension TaskStore
{
    func save()
    {
        let allTasks = root.allTasksRecursively()
        
        var archive = [TaskArchive]()
        
        for task in allTasks
        {
            archive.append(TaskArchive(with: task))
        }
        
        NSKeyedArchiver.archiveRootObject(archive, toFile: TaskStore.filePath)
    }
    
    func load()
    {
        // read task archives
        guard let archive = NSKeyedUnarchiver.unarchiveObject(withFile: TaskStore.filePath) as? [TaskArchive]
        else
        {
            return
        }
        
        // create task hash map
        var tasksByUuid = [String: Task]()
        
        for archiveTask in archive
        {
            let task = archiveTask.task
            
            tasksByUuid[task.uuid] = task
        }
        
        // connect task hierarchy
        for archiveTask in archive
        {
            let task = archiveTask.task
            
            if let containerUuid = archiveTask.containerUuidForDecoding
            {
                task.container = tasksByUuid[containerUuid]
            }
            
            if let elementUuids = archiveTask.elementUuidsForDecoding
            {
                var elements = [Task]()
                
                for elementUuid in elementUuids
                {
                    if let element = tasksByUuid[elementUuid]
                    {
                        elements.append(element)
                    }
                }
                
                task.elements = elements
            }
        }
        
        // find root and reset
        var unarchivedRoot: Task?
        
        for task in tasksByUuid.values
        {
            if task.container == nil
            {
                if unarchivedRoot != nil
                {
                    print("Error: found multiple root containers in unarchived tasks")
                    return
                }
                
                unarchivedRoot = task
            }
        }
        
        guard let root = unarchivedRoot else
        {
            print("Error: found no root container in unarchived tasks")
            return
        }
        
        reset(with: root)
    }
    
    private static let filePath = Bundle.main.bundlePath + "/UserData.plist"
}

extension Task
{
    func allTasksRecursively() -> [Task]
    {
        var tasks = [self]
        
        if let elements = elements
        {
            for task in elements
            {
                tasks.append(contentsOf: task.allTasksRecursively())
            }
        }
        
        return tasks
    }
}

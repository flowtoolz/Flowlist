//
//  TaskStorePersister.swift
//  TodayList
//
//  Created by Sebastian on 14/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Foundation
import Flowtoolz

let taskPersister = TaskPersister()

class TaskPersister
{
    fileprivate init() {}
    
    func save()
    {
        var archive = [ArchiveTask]()
        
        for task in taskStore.tasks
        {
            archive.append(ArchiveTask(withTask: task))
        }
        
        NSKeyedArchiver.archiveRootObject(archive, toFile: filePath)
    }
    
    func load()
    {
        guard let archive = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [ArchiveTask]
        else
        {
            return
        }
        
        taskStore.tasks.removeAll()
        
        for archiveTask in archive
        {
            taskStore.tasks.append(archiveTask.task)
        }
    }
    
    private let filePath = Bundle.main.bundlePath + "/UserData.plist"
}

class ArchiveTask: NSObject, NSCoding
{
    required convenience init?(coder aDecoder: NSCoder)
    {
        let task = Task()
        
        task.title = aDecoder.decodeObject(forKey: "title") as? String
        task.state = Task.State(rawValue: aDecoder.decodeInteger(forKey: "state"))
        
        self.init(withTask: task)
    }
    
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(task.title, forKey: "title")
        
        if let stateInteger = task.state?.rawValue
        {
            aCoder.encode(stateInteger, forKey: "state")
        }
    }
    
    init(withTask task: Task)
    {
        self.task = task
    }
    
    var task: Task
}

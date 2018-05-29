//
//  TaskArchive.swift
//  TodayList
//
//  Created by Sebastian on 14/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import Foundation

class TaskArchive: NSObject, NSCoding
{
    required convenience init?(coder aDecoder: NSCoder)
    {
        guard let uuid = aDecoder.decodeObject(forKey: "uuid") as? String else
        {
            Swift.print("Error decoding Task: could not decode UUID string")
            return nil
        }
        
        let title = aDecoder.decodeObject(forKey: "title") as? String
        let state = Task.State(rawValue: aDecoder.decodeInteger(forKey: "state"))
        
        self.init(with: Task(with: uuid, title: title, state: state))
        
        elementUuidsForDecoding = aDecoder.decodeObject(forKey: "elementUuids") as? [String]
    }
    
    var elementUuidsForDecoding: [String]?
    
    func encode(with aCoder: NSCoder)
    {
        aCoder.encode(task.uuid, forKey: "uuid")
        
        if let title = task.title
        {
            aCoder.encode(title, forKey: "title")
        }
        
        if let stateInteger = task.state?.rawValue
        {
            aCoder.encode(stateInteger, forKey: "state")
        }
        
        if task.subtasks.count > 0
        {
            var subtaskUuids = [String]()
            
            for subtask in task.subtasks
            {
                subtaskUuids.append(subtask.uuid)
            }
            
            aCoder.encode(subtaskUuids, forKey: "elementUuids")
        }
    }
    
    init(with task: Task)
    {
        self.task = task
    }
    
    let task: Task
}

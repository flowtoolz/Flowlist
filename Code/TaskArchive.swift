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
        let title = aDecoder.decodeObject(forKey: "title") as? String
        let state = Task.State(rawValue: aDecoder.decodeInteger(forKey: "state"))
        
        self.init(with: Task(with: title, state: state))
    }
    
    func encode(with aCoder: NSCoder)
    {
        if let title = task.title
        {
            aCoder.encode(title, forKey: "title")
        }
        
        if let stateInteger = task.state?.rawValue
        {
            aCoder.encode(stateInteger, forKey: "state")
        }
    }
    
    init(with task: Task)
    {
        self.task = task
    }
    
    var task: Task
}

//
//  TL_Model.swift
//  TodayList
//
//  Created by Sebastian Fichtner on 09.05.15.
//  Copyright (c) 2015 Flowtoolz. All rights reserved.
//

import Foundation

class TL_Model
{
    var taskArray = [TL_Task]()
    
    func addTask(task: TL_Task)
    {
        taskArray.append(task)
    }
    
    func getTasksOfToday() -> [TL_Task]
    {
        // TODO: do the filtering
        return taskArray
    }
    
    // MARK: initialization
    
    func initialize()
    {
        
    }
    
    // MARK: singleton access
    
    private init()
    {
        initialize()
    }
    
    class var sharedInstance: TL_Model
    {
        struct staticData
        {
            static var instance: TL_Model?
            static var token: dispatch_once_t = 0
        }
        
        dispatch_once(&staticData.token)
            {
                staticData.instance = TL_Model()
        }
        
        return staticData.instance!
    }
}
//
//  Task.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

class Task
{
    var title: String?
    
    var state: State?
    
    enum State: Int
    {
        // state == nil is default and kind of a backlog or "no specific state" 
        case inProgress, onHold, done, deleted
    }
}


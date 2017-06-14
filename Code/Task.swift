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
    
    var state: State? = .active
    
    enum State: Int
    {
        case active, done
    }
}


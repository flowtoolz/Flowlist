//
//  TaskListScrollView.swift
//  Flowlist
//
//  Created by Sebastian on 18/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit

class TaskListTableView: NSTableView
{
    override func keyDown(with event: NSEvent)
    {
        if event.keyCode == 36
        {
            nextResponder?.keyDown(with: event)
        }
        else
        {
            super.keyDown(with: event)
        }
    }
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        
        taskListDelegate?.taskListTableViewWasClicked(self)
    }
    
    var taskListDelegate: TaskListTableViewDelegate?
}

protocol TaskListTableViewDelegate
{
    func taskListTableViewWasClicked(_ view: TaskListTableView)
}

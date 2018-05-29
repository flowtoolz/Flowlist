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
    override func flagsChanged(with event: NSEvent)
    {
        super.flagsChanged(with: event)
        
        cmd = event.modifierFlags.contains(.command)
    }
    
    override func keyDown(with event: NSEvent)
    {
        //Swift.print("\(event.keyCode)")
        
        switch event.keyCode
        {
        case 36:
            nextResponder?.keyDown(with: event)
        case 125, 126:
            if event.modifierFlags.contains(.command)
            {
                nextResponder?.keyDown(with: event)
            }
            else
            {
                super.keyDown(with: event)
            }
        default:
            super.keyDown(with: event)
        }
    }
    
    private var cmd = false
    
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

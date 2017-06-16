//
//  TaskListRow.swift
//  TodayList
//
//  Created by Sebastian on 13/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit

class TaskListRow: NSTableRowView
{
    convenience init(with task: Task?)
    {
        self.init()
        
        self.task = task
    }
    
    override func drawSelection(in dirtyRect: NSRect)
    {
        drawBackground(with: selectionColor)
    }
    
    override func drawBackground(in dirtyRect: NSRect)
    {
        let color = task?.state == .done ? doneColor : NSColor.white
        
        drawBackground(with: color)
    }
    
    private func drawBackground(with color: NSColor)
    {
        color.setFill()
        
        let selectionRect = NSInsetRect(bounds, 2, 1)
        
        let selectionPath = NSBezierPath(roundedRect: selectionRect,
                                         xRadius: 3,
                                         yRadius: 3)
        
        selectionPath.fill()
    }
    
    private weak var task: Task?
    
    private let selectionColor = NSColor(calibratedRed: 163.0/255.0,
                                         green: 205.0 / 255.0,
                                         blue: 254.0 / 255.0,
                                         alpha: 1)
    
    private let doneColor = NSColor(calibratedRed: 224.0 / 255.0,
                                         green: 224.0 / 255.0,
                                         blue: 224.0 / 255.0,
                                         alpha: 1)
}

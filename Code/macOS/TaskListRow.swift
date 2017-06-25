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
        let color = TaskView.selectionColor.withAlphaComponent(isEmphasized ? 1 : 0.5)
        
        drawBackground(with: color)
    }
    
    override func drawBackground(in dirtyRect: NSRect)
    {
        let color = task?.state == .done ? TaskView.doneColor : NSColor.white
        
        drawBackground(with: color)
    }
 
    private func drawBackground(with color: NSColor)
    {
        var drawRect = bounds
        
        drawRect.origin.y = TaskView.verticalGap / 2
        drawRect.size.height -= TaskView.verticalGap
        
        color.setFill()
        
        let selectionPath = NSBezierPath(roundedRect: drawRect,
                                         xRadius: 4,
                                         yRadius: 4)
        
        selectionPath.fill()
    }
    
    private weak var task: Task?
}

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
    override func drawSelection(in dirtyRect: NSRect)
    {
        drawBackground(with: selectionColor)
    }
    
    override func drawBackground(in dirtyRect: NSRect)
    {
        drawBackground(with: NSColor.white)
    }
    
    private func drawBackground(with color: NSColor)
    {
        let selectionRect = NSInsetRect(bounds, 2, 1)
        
        color.setFill()
        
        let selectionPath = NSBezierPath(roundedRect: selectionRect,
                                         xRadius: 3,
                                         yRadius: 3)
        
        selectionPath.fill()
    }
    
    private let selectionColor = NSColor(calibratedRed: 218.0/255.0,
                                         green: 238.0 / 255.0,
                                         blue: 1,
                                         alpha: 1)
}

//
//  ListHeaderView.swift
//  Flowlist
//
//  Created by Sebastian on 17/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit

class ListHeaderView: NSView
{
    override func draw(_ dirtyRect: NSRect)
    {
        NSColor.white.setFill()
        
        let selectionRect = NSInsetRect(bounds, 2, 1)
        
        let selectionPath = NSBezierPath(roundedRect: selectionRect,
                                         xRadius: 3,
                                         yRadius: 3)
        
        selectionPath.fill()
    }
}

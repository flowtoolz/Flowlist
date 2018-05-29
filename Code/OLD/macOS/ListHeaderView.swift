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
        
        let selectionPath = NSBezierPath(roundedRect: dirtyRect,
                                         xRadius: 4,
                                         yRadius: 4)
        
        selectionPath.fill()
    }
}

//
//  TaskListCell.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit

class TaskListCell: NSView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        initialize()
    }
    
    required init?(coder: NSCoder)
    {
        super.init(coder: coder)
        
        initialize()
    }
    
    private func initialize()
    {
        self.identifier = TaskListCell.reuseIdentifier
        
        titleField.autoPinEdgesToSuperviewEdges()
    }
    
    static let reuseIdentifier = "TaskListCellIdentifier"
    
    func configure(with task: Task)
    {
        titleField.stringValue = task.title ?? "Untitled Task"
    }
    
    private lazy var titleField: NSTextField =
    {
        let textField = NSTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.isEditable = false
        textField.font = NSFont.systemFont(ofSize: 12)
        
        self.addSubview(textField)
        
        return textField
    }()
}

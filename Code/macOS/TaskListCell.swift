//
//  TaskListCell.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit

class TaskListCell: NSView, NSTextFieldDelegate
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
        
        layoutTitleField()
        layoutCheckBox()
    }
    
    static let reuseIdentifier = "TaskListCellIdentifier"
    
    func configure(with task: Task)
    {
        self.task = task
        
        titleField.stringValue = task.title ?? ""
        updateCheckBox()
    }
    
    // MARK: - Title Field
    
    func startEditingTitle()
    {
        titleField.selectText(self)
    }
    
    var isTitleEditingEnabled: Bool
    {
        set
        {
            titleField.isEditable = newValue
        }
        
        get
        {
            return titleField.isEditable
        }
    }
    
    func control(_ control: NSControl, textShouldEndEditing fieldEditor: NSText) -> Bool
    {
        guard let text = fieldEditor.string else
        {
            return false
        }
        
        task?.title = text
        
        return true
    }
    
    private func layoutTitleField()
    {
        titleField.autoAlignAxis(.horizontal, toSameAxisOf: self)
        titleField.autoPinEdge(toSuperviewEdge: .left, withInset: 36)
        titleField.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
    }
    
    private lazy var titleField: NSTextField =
    {
        let textField = NSTextField()
        textField.isBordered = false
        textField.drawsBackground = false
        textField.isBezeled = false
        textField.isEditable = true
        textField.font = NSFont.systemFont(ofSize: 13)
        textField.delegate = self
        textField.placeholderString = "Untitled"
        textField.lineBreakMode = .byTruncatingTail
        
        self.addSubview(textField)
        
        return textField
    }()
    
    // MARK: - Check Button
    
    private func layoutCheckBox()
    {
        checkBox.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero, excludingEdge: .right)
        checkBox.autoConstrainAttribute(.width, to: .height, of: checkBox)
    }
    
    private lazy var checkBox: NSButton =
    {
        let button = NSButton.newAutoLayout()
        self.addSubview(button)
        
        button.bezelStyle = NSBezelStyle.regularSquare
        button.title = ""
        button.action = #selector(checkBoxClicked)
        button.target = self
        button.imageScaling = .scaleNone
        button.image = NSImage(named: "checkbox_unchecked")
        button.isBordered = false
        button.layer?.backgroundColor = NSColor.clear.cgColor
        
        return button
    }()
    
    func checkBoxClicked()
    {
        boxIsChecked = !boxIsChecked
        
        task?.state = boxIsChecked ? .done : .active
        
        updateCheckBox()
    }
    
    private func updateCheckBox()
    {
        let imageName = task?.state == .done ? "checkbox_checked" : "checkbox_unchecked"
        
        checkBox.image = NSImage(named: imageName)
    }
    
    private var boxIsChecked = false
    
    // MARK: - Task
    
    private var task: Task?
}

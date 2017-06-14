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
        
        updateTitleField()
        updateCheckBox()
    }
    
    // MARK: - Title Field
    
    func updateTitleField()
    {
        titleField.stringValue = self.task?.title ?? ""
    }
    
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
        task?.title = String(withNonEmpty: fieldEditor.string)
        
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
        button.image = TaskListCell.checkBoxImageEmpty
        button.isBordered = false
        button.layer?.backgroundColor = NSColor.clear.cgColor
        
        return button
    }()
    
    func checkBoxClicked()
    {
        boxIsChecked = !boxIsChecked
        
        task?.state = boxIsChecked ? .done : nil
        
        updateCheckBox()
    }
    
    private func updateCheckBox()
    {
        let isChecked = task?.state == .done
        
        checkBox.image = checkBoxImage(isChecked)
    }
    
    private var boxIsChecked = false
    
    private func checkBoxImage(_ checked: Bool) -> NSImage?
    {
        return checked ? TaskListCell.checkBoxImageChecked : TaskListCell.checkBoxImageEmpty
    }
    
    private static let checkBoxImageEmpty = NSImage(named: "checkbox_unchecked")
    private static let checkBoxImageChecked = NSImage(named: "checkbox_checked")
    
    // MARK: - Task
    
    private var task: Task?
}

//
//  TaskList.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit
import PureLayout

class TaskList: NSScrollView, NSTableViewDelegate, NSTableViewDataSource
{
    // MARK: - Table View
    
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
        drawsBackground = false
        
        hasVerticalScroller = true
        
        documentView = tableView
    }
    
    private lazy var tableView: NSTableView =
    {
        let view = NSTableView()
        
        let column = NSTableColumn(identifier: TaskListCell.reuseIdentifier)
        column.title = "Task List Title"
        view.addTableColumn(column)
        
        view.allowsMultipleSelection = true
        view.backgroundColor = NSColor.clear
        view.headerView = nil
    
        view.dataSource = self
        view.delegate = self
        
        return view
    }()
    
    // MARK: - Keyboard Short Cuts
    
    override func keyDown(with event: NSEvent)
    {
        //Swift.print(event.keyCode.description)
        
        let cmd = event.modifierFlags.contains(.command)
     
        switch event.keyCode
        {
        case 1:
            if cmd
            {
                taskStore.save()
            }
        case 37:
            if cmd
            {
                taskStore.load()
                tableView.reloadData()
            }
        case 36, 45:
            if cmd
            {
                createNewTask()
            }
        case 51:
            deleteSelectedTasks()
        default:
            break
        }
    }
    
    override func flagsChanged(with event: NSEvent)
    {
        ensureCmdPlusReturnWorks(modifiersChangedWith: event)
    }
    
    private func ensureCmdPlusReturnWorks(modifiersChangedWith event: NSEvent)
    {
        guard event.modifierFlags.contains(.command),
            tableView.selectedRowIndexes.count == 1
        else
        {
            disabledCell?.isTitleEditingEnabled = true
            
            disabledCell = nil
            
            return
        }
        
        if let index = tableView.selectedRowIndexes.max(),
            let cell = tableView.view(atColumn: 0,
                                      row: index,
                                      makeIfNecessary: false) as? TaskListCell
        {
            cell.isTitleEditingEnabled = false
            
            disabledCell = cell
        }
    }
    
    private var disabledCell: TaskListCell?

    // MARK: - Editing the List
    
    private func deleteSelectedTasks()
    {
        let selectedIndexSet = tableView.selectedRowIndexes
        
        guard let indexOfFirstDeletion = selectedIndexSet.min() else
        {
            return
        }
        
        tableView.beginUpdates()
        
        taskStore.removeTasks(at: Array(selectedIndexSet))
        
        tableView.removeRows(at: selectedIndexSet,
                             withAnimation: NSTableViewAnimationOptions.slideUp)
        
        tableView.endUpdates()
        
        let indexToSelect = max(indexOfFirstDeletion - 1, 0)
        
        tableView.selectRowIndexes([indexToSelect], byExtendingSelection: false)
    }
    
    private func createNewTask()
    {
        var indexOfNewTask = 0
        
        if let lastSelectedIndex = tableView.selectedRowIndexes.max()
        {
            indexOfNewTask = lastSelectedIndex + 1
        }
        
        tableView.beginUpdates()
        
        taskStore.tasks.insert(Task(),
                               at: indexOfNewTask)
        
        tableView.insertRows(at: [indexOfNewTask],
                             withAnimation: NSTableViewAnimationOptions.slideDown)
        
        tableView.endUpdates()
        
        tableView.scrollRowToVisible(indexOfNewTask)
        tableView.selectRowIndexes([indexOfNewTask], byExtendingSelection: false)
        
        if let cell = tableView.view(atColumn: 0,
                                     row: indexOfNewTask,
                                     makeIfNecessary: false) as? TaskListCell
        {
            cell.startEditingTitle()
        }
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return 36
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
    {
        return TaskListRow()
    }
    
    // MARK: - Table View Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return taskStore.tasks.count
    }
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        guard tableColumn?.identifier == TaskListCell.reuseIdentifier else
        {
            Swift.print("warning: tableColumn has weird or nil identifier: \(tableColumn?.identifier ?? "nil")")
            return nil
        }

        let cell = tableView.make(withIdentifier: TaskListCell.reuseIdentifier,
                                  owner: self) as? TaskListCell ?? TaskListCell()
        
        cell.configure(with: taskStore.tasks[row])
        
        return cell
    }
}

//
//  TaskList.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit
import PureLayout

class TaskList: NSScrollView, NSTableViewDelegate, NSTableViewDataSource, TaskListCellDelegate
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
    
    lazy var tableView: NSTableView =
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
        case 36:
                createNewTask(createContainer: !cmd)
        case 45:
            if cmd
            {
                createNewTask()
            }
        case 51:
            deleteSelectedTasks()
        case 123:
            filterBySuperContainer()
        case 124:
            filterBySelectedTask()
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

    // MARK: - Editing and Filtering the List
    
    private func filterBySuperContainer()
    {
        if taskStore.filterBySuperContainer()
        {
            tableView.reloadData()
            
            updateTableSelection()
        }
    }
    
    private func filterBySelectedTask()
    {
        if taskStore.filterBySelectedTask()
        {
            tableView.reloadData()
            
            updateTableSelection()
        }
    }
    
    private func deleteSelectedTasks()
    {
        let selectedIndexSet = IndexSet(taskStore.selectedIndexes)
        
        tableView.beginUpdates()
       
        guard taskStore.deleteSelectedTasks() else
        {
            tableView.endUpdates()
            return
        }
        
        tableView.removeRows(at: selectedIndexSet,
                             withAnimation: NSTableViewAnimationOptions.slideUp)
        
        tableView.endUpdates()
        
        updateTableSelection()
    }
    
    private func createNewTask(createContainer: Bool = false)
    {
        if createContainer && taskStore.selectedIndexes.count > 1
        {
            groupSelectedTasks()
        }
        else
        {
            createTask()
        }
    }
    
    private func groupSelectedTasks()
    {
        let selectedIndexes = taskStore.selectedIndexes
        
        tableView.beginUpdates()
        
        guard let groupIndex = taskStore.groupSelectedTasks(as: Task()) else
        {
            tableView.endUpdates()
            return
        }
        
        tableView.removeRows(at: IndexSet(selectedIndexes),
                             withAnimation: NSTableViewAnimationOptions.slideUp)
        
        tableView.insertRows(at: [groupIndex],
                             withAnimation: NSTableViewAnimationOptions.slideDown)
        
        tableView.endUpdates()
        
        startEditing(at: groupIndex)
    }
    
    private func createTask()
    {
        tableView.beginUpdates()
        
        let index = taskStore.add(Task())
        
        tableView.insertRows(at: [index],
                             withAnimation: NSTableViewAnimationOptions.slideDown)
        
        tableView.endUpdates()
        
        startEditing(at: index)
    }
    
    private func startEditing(at index: Int)
    {
        tableView.scrollRowToVisible(index)
        
        if taskStore.selectedIndexes != [index]
        {
            taskStore.selectedIndexes = [index]
        }
        
        updateTableSelection()
        
        if let cell = tableView.view(atColumn: 0,
                                     row: index,
                                     makeIfNecessary: false) as? TaskListCell
        {
            cell.startEditingTitle()
        }
    }
    
    private func updateTableSelection()
    {
        tableView.selectRowIndexes(IndexSet(taskStore.selectedIndexes),
                                   byExtendingSelection: false)
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return 36
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
    {
        return TaskListRow(with: taskStore.task(at: row))
    }
    
    func tableView(_ tableView: NSTableView,
                   selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
    {
        taskStore.selectedIndexes = Array(proposedSelectionIndexes)
        
        return proposedSelectionIndexes
    }
    
    // MARK: - Table View Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return taskStore.list.count
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
        
        cell.configure(with: taskStore.list[row])
        cell.delegate = self
        
        return cell
    }
    
    // MARK: - TaskListCellDelegate
    
    func viewNeedsUpdate(_ view: NSView)
    {
        let row = tableView.row(for: view)
        
        guard let task = taskStore.task(at: row) else
        {
            return
        }

        tableView.beginUpdates()
        
        let animationOptions: NSTableViewAnimationOptions = task.state != .done ? [] : NSTableViewAnimationOptions.slideDown
        
        tableView.hideRows(at: [row], withAnimation: [])
        
        tableView.unhideRows(at: [row], withAnimation: animationOptions)
        
        updateTableSelection()
        
        tableView.endUpdates()
    }
}

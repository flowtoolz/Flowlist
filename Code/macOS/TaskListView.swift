//
//  TaskList.swift
//  TodayList
//
//  Created by Sebastian on 12/06/17.
//  Copyright © 2017 Flowtoolz. All rights reserved.
//

import AppKit
import PureLayout
import Flowtoolz

class TaskListView: NSScrollView, NSTableViewDelegate, NSTableViewDataSource, TaskViewDelegate, TaskListDelegate, Subscriber
{
    // MARK: - Table View
    
    convenience init()
    {
        self.init(frame: NSRect.zero)
        
        initialize()
    }
    
    private func initialize()
    {
        taskList.delegate = self
        
        translatesAutoresizingMaskIntoConstraints = false
        drawsBackground = false
        automaticallyAdjustsContentInsets = false
        
        documentView = tableView
        
        contentInsets = NSEdgeInsetsMake(10, 0, 10, 0)
    }
    
    lazy var tableView: NSTableView =
    {
        let view = NSTableView()
        
        let column = NSTableColumn(identifier: TaskView.reuseIdentifier)
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
        case 49:
            createNewTask(at: 0)
        case 51:
            deleteSelectedTasks()
        case 123:
            goToSuperContainer()
        case 124:
            goToSelectedTask()
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
                                      makeIfNecessary: false) as? TaskView
        {
            cell.isTitleEditingEnabled = false
            
            disabledCell = cell
        }
    }
    
    private var disabledCell: TaskView?
    
    // MARK: - Reacting to Updates
    
    func didDeleteSubtasks(at indexes: [Int])
    {
        tableView.beginUpdates()
        tableView.removeRows(at: IndexSet(indexes), withAnimation: .slideUp)
        tableView.endUpdates()
    }
    
    func didInsertSubtasks(at indexes: [Int])
    {
        tableView.beginUpdates()
        tableView.insertRows(at: IndexSet(indexes), withAnimation: .slideDown)
        tableView.endUpdates()
    }
    
    func didDeleteListContainer()
    {
        tableView.beginUpdates()
        tableView.removeRows(at: IndexSet(integersIn: 0 ..< tableView.numberOfRows),
                             withAnimation: .slideUp)
        tableView.endUpdates()
    }
    
    // MARK: - Editing and Filtering the List
    
    private func goToSuperContainer()
    {
        if taskList.goToSuperContainer()
        {
            tableView.reloadData()
            
            updateTableSelection()
        }
    }
    
    private func goToSelectedTask()
    {
        if taskList.goToSelectedTask()
        {
            tableView.reloadData()
            
            updateTableSelection()
        }
    }
    
    private func deleteSelectedTasks()
    {
        guard taskList.deleteSelectedTasks() else
        {
            return
        }
        
        updateTableSelection()
    }
    
    private func createNewTask(at index: Int? = nil, createContainer: Bool = false)
    {
        if createContainer && taskList.selectedIndexes.count > 1
        {
            groupSelectedTasks()
        }
        else
        {
            createTask(at: index)
        }
    }
    
    private func groupSelectedTasks()
    {
        guard let groupIndex = taskList.groupSelectedTasks(as: Task()) else
        {
            return
        }
        
        startEditing(at: groupIndex)
    }
    
    private func createTask(at index: Int?)
    {
        let index = taskList.add(Task(), at: index)
        
        startEditing(at: index)
    }
    
    private func startEditing(at index: Int)
    {
        if index == 0
        {
            jumpToTop()
        }
        else
        {
            tableView.scrollRowToVisible(index)
        }
        
        if taskList.selectedIndexes != [index]
        {
            taskList.selectedIndexes = [index]
        }
        
        updateTableSelection()
        
        if let cell = tableView.view(atColumn: 0,
                                     row: index,
                                     makeIfNecessary: false) as? TaskView
        {
            cell.startEditingTitle()
        }
    }
    
    func jumpToTop()
    {
        var newOrigin = contentView.bounds.origin
        
        newOrigin.y = -10
        
        contentView.setBoundsOrigin(newOrigin)
    }
    
    private func updateTableSelection()
    {
        tableView.selectRowIndexes(IndexSet(taskList.selectedIndexes),
                                   byExtendingSelection: false)
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return 36
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
    {
        return TaskListRow(with: taskList.task(at: row))
    }
    
    func tableView(_ tableView: NSTableView,
                   selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet
    {
        taskList.selectedIndexes = Array(proposedSelectionIndexes)
        
        return proposedSelectionIndexes
    }
    
    // MARK: - Table View Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return taskList.numberOfTasks
    }
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        guard tableColumn?.identifier == TaskView.reuseIdentifier else
        {
            Swift.print("warning: tableColumn has weird or nil identifier: \(tableColumn?.identifier ?? "nil")")
            return nil
        }

        let cell = tableView.make(withIdentifier: TaskView.reuseIdentifier,
                                  owner: self) as? TaskView ?? TaskView()
        
        if let task = taskList.task(at: row)
        {
            cell.configure(with: task)
        }
        
        cell.delegate = self
        
        return cell
    }
    
    // MARK: - TaskListCellDelegate
    
    func taskViewNeedsUpdate(_ view: NSView)
    {
        let row = tableView.row(for: view)
        
        guard row >= 0 else { return }

        tableView.beginUpdates()

        tableView.hideRows(at: [row], withAnimation: [])
        
        tableView.unhideRows(at: [row], withAnimation: [])
        
        updateTableSelection()
        
        tableView.endUpdates()
    }
    
    // MARK: - Task List
    
    private var taskList = TaskList()
}

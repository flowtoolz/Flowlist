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

class TaskListView: NSView, NSTableViewDelegate, NSTableViewDataSource, TaskListDelegate, Subscriber, Sender, TaskListTableViewDelegate, TaskViewTextFieldDelegate
{
    // MARK: - Table View
    
    convenience init(with list: TaskList)
    {
        self.init(frame: NSRect.zero)
        
        taskList = list
        
        initialize()
    }
    
    private func initialize()
    {
        taskList?.delegate = self
        
        translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero, excludingEdge: .top)
        scrollView.autoPinEdge(.top, to: .bottom, of: headerView, withOffset: 10)
        
        headerView.autoPinEdge(toSuperviewEdge: .left)
        headerView.autoPinEdge(toSuperviewEdge: .right)
        headerView.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        
        headerView.autoSetDimension(.height, toSize: 36)
        
        titleField.autoAlignAxis(.horizontal, toSameAxisOf: headerView)
        titleField.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
        titleField.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        
        updateTitle()
    }
    
    private lazy var titleField: NSTextField =
    {
        let field = NSTextField.newAutoLayout()
        self.headerView.addSubview(field)
        
        field.textColor = NSColor.black
        field.font = NSFont.systemFont(ofSize: 13)
        
        field.setContentCompressionResistancePriority(0.1, for: .horizontal)
        field.lineBreakMode = .byTruncatingTail
        field.drawsBackground = false
        field.alignment = .center
        field.isEditable = false
        field.isBezeled = false
        field.isBordered = false
        field.isSelectable = false
        
        return field
    }()
    
    func updateTitle()
    {
        titleField.stringValue = taskList?.container?.title ?? ""
    }
    
    private func hideHeader()
    {
        headerView.isHidden = true
    }
    
    private func showHeader()
    {
        headerView.isHidden = false
    }
    
    private lazy var headerView: ListHeaderView =
    {
        let view = ListHeaderView()
        self.addSubview(view)
        
        return view
    }()
    
    lazy var scrollView: NSScrollView =
    {
        let view = NSScrollView.newAutoLayout()
        self.addSubview(view)
        
        view.drawsBackground = false
        
        view.automaticallyAdjustsContentInsets = false
        view.contentInsets = NSEdgeInsetsMake(0, 0, 10, 0)
        
        view.documentView = self.tableView
        
        return view
    }()
    
    lazy var tableView: TaskListTableView =
    {
        let view = TaskListTableView()
        
        let column = NSTableColumn(identifier: TaskView.reuseIdentifier)
        
        view.addTableColumn(column)
        
        view.allowsMultipleSelection = true
        view.backgroundColor = NSColor.clear
        view.headerView = nil
    
        view.dataSource = self
        view.delegate = self
        view.taskListDelegate = self
        
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
                store.save()
            }
        case 37:
            if cmd
            {
                store.load()
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
            send(TaskListView.wantsToGiveUpFocusToTheLeft)
            //goToSuperContainer()
        case 124:
            send(TaskListView.wantsToGiveUpFocusToTheRight)
            //goToSelectedTask()
        default:
            break
        }
    }
    
    static let wantsToGiveUpFocusToTheRight = "TaskListViewWantsToGiveUpFocusToTheRight"
    
    static let wantsToGiveUpFocusToTheLeft = "TaskListViewWantsToGiveUpFocusToTheLeft"
    
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
    
    func didInsertSubtask(at index: Int)
    {
        tableView.beginUpdates()
        tableView.insertRows(at: [index], withAnimation: .slideDown)
        tableView.endUpdates()
    }
    
    func didChangeListContainer()
    {
        updateTitle()
        
        tableView.beginUpdates()
        tableView.removeRows(at: IndexSet(integersIn: 0 ..< tableView.numberOfRows),
                             withAnimation: .slideUp)
        tableView.endUpdates()
        
        let numberOfTasks = taskList?.numberOfTasks ?? 0
        
        if numberOfTasks > 0
        {
            tableView.beginUpdates()
            tableView.insertRows(at: IndexSet(integersIn: 0 ..< numberOfTasks),
                                 withAnimation: .slideUp)
            tableView.endUpdates()
        }
    }
    
    func didChangeListContainerTitle()
    {
        updateTitle()
    }
    
    func didChangeTitleOfSubtask(at index: Int)
    {
        if let taskView = tableView.view(atColumn: 0,
                                         row: index,
                                         makeIfNecessary: false) as? TaskView
        {
            taskView.updateTitleField()
        }
    }
    
    func didChangeStateOfSubtask(at index: Int)
    {
        if let taskView = tableView.view(atColumn: 0,
                                         row: index,
                                         makeIfNecessary: false) as? TaskView
        {
            taskView.updateCheckBox()
        }
        
        tableView.rowView(atRow: index, makeIfNecessary: false)?.display()
    }
    
    func taskListTableViewWasClicked(_ view: TaskListTableView)
    {
        send(TaskListView.tableViewWasClicked)
    }
    
    func taskViewTextFieldDidBecomeFirstResponder(_ textField: TaskViewTextField)
    {
        send(TaskListView.tableViewWasClicked)
    }
    
    static let tableViewWasClicked = "TaskListTableViewWasClicked"
    
    // MARK: - Editing and Filtering the List
    
    private func goToSuperContainer()
    {
        if taskList?.goToSuperContainer() ?? false
        {
            tableView.reloadData()
            
            updateTableSelection()
        }
    }
    
    private func goToSelectedTask()
    {
        if taskList?.goToSelectedTask() ?? false
        {
            tableView.reloadData()
            
            updateTableSelection()
        }
    }
    
    private func deleteSelectedTasks()
    {
        guard taskList?.deleteSelectedTasks() ?? false else
        {
            return
        }
        
        updateTableSelection()
    }
    
    private func createNewTask(at index: Int? = nil, createContainer: Bool = false)
    {
        if createContainer && taskList?.selectedIndexes.count ?? 0 > 1
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
        guard let groupIndex = taskList?.groupSelectedTasks(as: Task()) else
        {
            return
        }
        
        startEditing(at: groupIndex)
    }
    
    private func createTask(at index: Int?)
    {
        if let index = taskList?.add(Task(), at: index)
        {
            startEditing(at: index)
        }
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
        
        if let taskList = taskList, taskList.selectedIndexes != [index]
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
        var newOrigin = scrollView.contentView.bounds.origin
        
        newOrigin.y = 0
        
        scrollView.contentView.setBoundsOrigin(newOrigin)
    }
    
    func updateTableSelection()
    {
        let selection = taskList?.selectedIndexes ?? []
        
        guard selection.max() ?? 0 < tableView.numberOfRows else { return }
        
        tableView.selectRowIndexes(IndexSet(selection),
                                   byExtendingSelection: false)
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return 36
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView?
    {
        return TaskListRow(with: taskList?.task(at: row))
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        //Swift.print("selection did change: \(Array(tableView.selectedRowIndexes).description)")
        taskList?.selectedIndexes = Array(tableView.selectedRowIndexes)
    }
    
    // MARK: - Table View Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return taskList?.numberOfTasks ?? 0
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
        
        cell.titleField.taskViewTextFieldDelegate = self
        
        if let task = taskList?.task(at: row)
        {
            cell.configure(with: task)
        }
        
        return cell
    }
    
    // MARK: - Task List
    
    private(set) weak var taskList: TaskList?
}

func logFirstResponder()
{
    guard NSApp.mainWindow != nil else
    {
        Swift.print("main window is nil")
        return
    }
    
    guard let firstResponder = NSApp.mainWindow?.firstResponder else
    {
        Swift.print("main window has no first responder")
        return
    }
    
    Swift.print("first responder: \(firstResponder.className) (\(ObjectIdentifier(firstResponder).debugDescription))")
}

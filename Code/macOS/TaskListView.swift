import AppKit
import PureLayout
import SwiftObserver

class TaskListView: NSView, NSTableViewDelegate, NSTableViewDataSource, TaskListTableViewDelegate, TaskViewTextFieldDelegate, Observer, Observable
{
    // MARK: - Life Cycle
    
    init(with list: TaskListViewModel)
    {
        super.init(frame: NSRect.zero)
        
        taskList = list
        
        observe(list)
        {
            [weak self] in
            
            self?.didReceive($0)
        }
        
        translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero, excludingEdge: .top)
        scrollView.autoPinEdge(.top,
                               to: .bottom,
                               of: headerView,
                               withOffset: 10 - (TaskView.verticalGap / 2))
        
        headerView.autoPinEdge(toSuperviewEdge: .left)
        headerView.autoPinEdge(toSuperviewEdge: .right)
        headerView.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        headerView.autoSetDimension(.height, toSize: 36)
        
        titleField.autoAlignAxis(.horizontal, toSameAxisOf: headerView)
        titleField.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
        titleField.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        
        updateTitle()
    }
    
    required init?(coder decoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit
    {
        stopAllObserving()
    }
    
    // MARK: - Header View
    
    private lazy var titleField: NSTextField =
    {
        let field = NSTextField.newAutoLayout()
        self.headerView.addSubview(field)
        
        field.textColor = NSColor.black
        field.font = NSFont.systemFont(ofSize: 13)
        
        field.setContentCompressionResistancePriority(NSLayoutConstraint.Priority(rawValue: 0.1), for: .horizontal)
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
        titleField.stringValue = taskList?.supertask?.title.value ?? ""
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
        
        view.wantsLayer = true
        view.layer?.borderColor = TaskView.borderColor.cgColor
        view.layer?.borderWidth = 1.0
        view.layer?.cornerRadius = 4.0
        
        return view
    }()
    
    // MARK: - Scrolling Table View
    
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
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(rawValue: TaskView.reuseIdentifier))
        
        view.addTableColumn(column)
        
        view.allowsMultipleSelection = true
        view.backgroundColor = NSColor.clear
        view.headerView = nil
    
        view.dataSource = self
        view.delegate = self
        view.taskListDelegate = self
        view.intercellSpacing = NSSize(width: 0, height: TaskView.verticalGap)
        
        return view
    }()
    
    // MARK: - Keyboard Short Cuts
    
    override func keyDown(with event: NSEvent)
    {
        //Swift.print(event.keyCode.description)
        
        let cmd = event.modifierFlags.contains(NSEvent.ModifierFlags.command)
     
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
            
            let numSelections = taskList?.selectedTasks.count ?? 0
            
            if numSelections == 0
            {
                createNewTask()
            }
            else if numSelections == 1
            {
                if cmd
                {
                    if let index = taskList?.selectedIndexesSorted.first
                    {
                        startEditing(at: index)
                    }
                }
                else
                {
                    createNewTask()
                }
            }
            else
            {
                if cmd
                {
                    if let index = taskList?.selectedIndexesSorted.first
                    {
                        startEditing(at: index)
                    }
                }
                else
                {
                    createNewTask(createContainer: true)
                }
            }
        case 45:
            if cmd
            {
                createNewTask(createContainer: true)
            }
        case 49:
            createTask(at: 0)
        case 51:
            if cmd
            {
                taskList?.checkOffFirstSelectedUncheckedTask()
                updateTableSelection()
            }
            else
            {
                deleteSelectedTasks()
            }
        case 123:
            send(.wantToGiveUpFocusToTheLeft)
        case 124:
            send(.wantToGiveUpFocusToTheRight)
        case 125:
            if cmd
            {
                _ = taskList?.moveSelectedTaskDown()
            }
        case 126:
            if cmd
            {
                _ = taskList?.moveSelectedTaskUp()
            }
        default:
            break
        }
    }
    
    // MARK: - Process List Events
    
    private func didReceive(_ event: TaskListViewModel.Event)
    {
        switch(event)
        {
        case .didNothing:
            break
            
        case .didChangeSelection:
            break
            
        case .didChangeSubtasksInTask(let index):
            subtasksChangedInTask(at: index)
            
        case .didChangeStateOfTask(let index):
            didChangeStateOfSubtask(at: index)
            
        case .didChangeTitleOfTask(let index):
            didChangeTitleOfSubtask(at: index)
            
        case .didChangeListContainer:
            didChangeListContainer()
            
        case .didChangeListContainerTitle:
            updateTitle()
            
        case .didInsertTask(let index):
            didInsertSubtask(at: index)
            
        case .didDeleteTasks(let indexes):
            didDeleteSubtasks(at: indexes)
            
        case .didMoveTask(let from, let to):
            didMoveSubtask(from: from, to: to)
        }
    }
    
    func didDeleteSubtasks(at indexes: [Int])
    {
        tableView.beginUpdates()
        tableView.removeRows(at: IndexSet(indexes), withAnimation: NSTableView.AnimationOptions.slideUp)
        tableView.endUpdates()
    }
    
    func didInsertSubtask(at index: Int)
    {
        tableView.beginUpdates()
        tableView.insertRows(at: [index], withAnimation: NSTableView.AnimationOptions.slideDown)
        tableView.endUpdates()
    }
    
    func didChangeListContainer()
    {
        updateTitle()
        
        tableView.beginUpdates()
        tableView.removeRows(at: IndexSet(integersIn: 0 ..< tableView.numberOfRows),
                             withAnimation: NSTableView.AnimationOptions.slideUp)
        tableView.endUpdates()
        
        let numberOfTasks = taskList?.numberOfTasks ?? 0
        
        if numberOfTasks > 0
        {
            tableView.beginUpdates()
            tableView.insertRows(at: IndexSet(integersIn: 0 ..< numberOfTasks),
                                 withAnimation: NSTableView.AnimationOptions.slideUp)
            tableView.endUpdates()
        }
    }
    
    func didChangeTitleOfSubtask(at index: Int)
    {
        guard index < tableView.numberOfRows,
            let taskView = tableView.view(atColumn: 0,
                                          row: index,
                                          makeIfNecessary: false) as? TaskView
        else
        {
            return
        }
        
        taskView.updateTitleField()
        
        if taskList?.selectedTasks.count ?? 0 > 1,
            let firstSelectedIndex = taskList?.selectedIndexesSorted.first,
            let firstSelectedTask = taskList?.task(at: firstSelectedIndex)
        {
            taskList?.selectedTasks[firstSelectedTask.hash] = nil
            
            if let nextEditingIndex = taskList?.selectedIndexesSorted.first
            {
                startEditing(at: nextEditingIndex)
            }
        }
    }
    
    func didChangeStateOfSubtask(at index: Int)
    {
        guard index < tableView.numberOfRows,
            let taskView = tableView.view(atColumn: 0,
                                          row: index,
                                          makeIfNecessary: false) as? TaskView
        else
        {
            return
        }
        
        taskView.updateCheckBox()
        
        tableView.rowView(atRow: index, makeIfNecessary: false)?.display()
    }
    
    func subtasksChangedInTask(at index: Int)
    {
        updateGroupIndicator(at: index)
    }
    
    private func updateGroupIndicator(at index: Int)
    {
        if let numberOfSubtasks = taskList?.task(at: index)?.numberOfSubtasks,
            numberOfSubtasks < 2,
            index < tableView.numberOfRows,
            let taskView = tableView.view(atColumn: 0,
                                          row: index,
                                          makeIfNecessary: false) as? TaskView
        {
            taskView.updateGroupIndicator()
        }
    }
    
    func didMoveSubtask(from: Int, to: Int)
    {
        tableView.beginUpdates()
        tableView.moveRow(at: from, to: to)
        tableView.endUpdates()
    }
    
    func taskListTableViewWasClicked(_ view: TaskListTableView)
    {
        send(.tableViewWasClicked)
    }
    
    func taskViewTextFieldDidBecomeFirstResponder(_ textField: TaskView.TextField)
    {
        send(.tableViewWasClicked)
    }
    
    // MARK: - Editing and Filtering the List
    
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
        if createContainer && taskList?.selectedTasks.count ?? 0 > 1
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
        guard let groupIndex = taskList?.groupSelectedTasks() else
        {
            return
        }
        
        startEditing(at: groupIndex)
    }
    
    private func createTask(at index: Int?)
    {
        let newTask = Task()
        
        if let indexOfNewTask = taskList?.add(newTask, at: index)
        {
            taskList?.selectedTasks = [newTask.hash : newTask]
            
            startEditing(at: indexOfNewTask)
        }
    }
    
    private func startEditing(at index: Int)
    {
        guard let taskList = taskList, let task = taskList.task(at: index) else
        {
            return
        }
       
        if index == 0
        {
            jumpToTop()
        }
        else
        {
            tableView.scrollRowToVisible(index)
        }
        
        taskList.selectedTasks[task.hash] = task
        
        updateTableSelection()
        
        if index < tableView.numberOfRows,
            let cell = tableView.view(atColumn: 0,
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
        let selection = taskList?.selectedIndexesSorted ?? []
        
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
        // Swift.print("selection did change: \(Array(tableView.selectedRowIndexes).description)")
        
        taskList?.selectSubtasks(at: Array(tableView.selectedRowIndexes))
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
        let taskViewReuseIdentifier = NSUserInterfaceItemIdentifier(TaskView.reuseIdentifier)
        
        guard tableColumn?.identifier == taskViewReuseIdentifier else
        {
            Swift.print("warning: tableColumn has weird or nil identifier: \(tableColumn?.identifier ?? NSUserInterfaceItemIdentifier(rawValue: "nil"))")
            return nil
        }

        let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: TaskView.reuseIdentifier),
                                  owner: self) as? TaskView ?? TaskView()
        
        cell.titleField.taskViewTextFieldDelegate = self
        
        if let task = taskList?.task(at: row)
        {
            cell.configure(with: task)
        }
        
        return cell
    }
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .none }
    
    enum Event
    {
        case none
        case wantToGiveUpFocusToTheRight
        case wantToGiveUpFocusToTheLeft
        case tableViewWasClicked
    }
    
    // MARK: - Task List
    
    private(set) weak var taskList: TaskListViewModel?
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

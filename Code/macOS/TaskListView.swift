import AppKit
import PureLayout
import SwiftObserver
import SwiftyToolz

class TaskListView: NSView, NSTableViewDelegate, NSTableViewDataSource, TaskListTableViewDelegate, TaskViewTextFieldDelegate, Observer, Observable
{
    // MARK: - Life Cycle
    
    init(with list: TaskListViewModel)
    {
        super.init(frame: NSRect.zero)
        
        // list
        
        taskList = list
        
        observe(list)
        {
            [weak self] in
            
            self?.didReceive($0)
        }
        
        // title
        
        titleField.stringValue = list.title.latestUpdate
        
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.titleField.stringValue = newTitle
        }
        
        // auto layout
        
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
        //Swift.print("key own. code: \(event.keyCode) characters: \(event.characters ?? "nil")")
     
        //interpretKeyEvents([event])
        
        let cmd = event.modifierFlags.contains(NSEvent.ModifierFlags.command)
     
        switch event.key
        {
        case .enter:
            let numSelections = taskList?.selection.count ?? 0
            
            if numSelections == 0
            {
                createNewTask()
            }
            else if numSelections == 1
            {
                if cmd
                {
                    if let index = taskList?.selection.indexes.first
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
                    if let index = taskList?.selection.indexes.first
                    {
                        startEditing(at: index)
                    }
                }
                else
                {
                    createNewTask(createContainer: true)
                }
            }
            
        case .space: createTask(at: 0)
            
        case .delete:
            if cmd
            {
                taskList?.checkOffFirstSelectedUncheckedTask()
                updateTableSelection()
            }
            else { deleteSelectedTasks() }
            
        case .left: send(.wantToGiveUpFocusToTheLeft)
            
        case .right: send(.wantToGiveUpFocusToTheRight)
            
        case .down: if cmd { _ = taskList?.moveSelectedTask(1) }
            
        case .up: if cmd { _ = taskList?.moveSelectedTask(-1) }
            
        case .unknown:
            didPress(characterKey: event.characters, withCommand: cmd)
        }
    }
    
    private func didPress(characterKey key: String?, withCommand cmd: Bool)
    {
        guard let key = key else { return }
        
        switch key
        {
        case "s": if cmd { store.save() }
        case "l":
            if cmd
            {
                store.load()
                tableView.reloadData()
            }
        case "n": if cmd { createNewTask(createContainer: true) }
        default: break
        }
    }
    
    // MARK: - Process List Events
    
    private func didReceive(_ event: TaskListViewModel.Event)
    {
        switch(event)
        {
        case .didChangeTaskTitle(let index):
            didChangeTitleOfSubtask(at: index)
        
        case .didChangeTaskList(let change):
            switch change
            {
            case .didInsertItems(let indexes):
                didInsertSubtask(at: indexes)
                
            case .didRemoveItems(let indexes):
                didDeleteSubtasks(at: indexes)
                
            case .didMoveItem(let from, let to):
                didMoveSubtask(from: from, to: to)
                
            case .didNothing: break
            }
        
        case .didNothing: break
        }
    }
    
    func didDeleteSubtasks(at indexes: [Int])
    {
        tableView.beginUpdates()
        tableView.removeRows(at: IndexSet(indexes),
                             withAnimation: NSTableView.AnimationOptions.slideUp)
        tableView.endUpdates()
    }
    
    func didInsertSubtask(at indexes: [Int])
    {
        tableView.beginUpdates()
        tableView.insertRows(at: IndexSet(indexes),
                             withAnimation: NSTableView.AnimationOptions.slideDown)
        tableView.endUpdates()
    }
    
    func didChangeTitleOfSubtask(at index: Int)
    {
        if taskList?.selection.count ?? 0 > 1,
            let firstSelectedIndex = taskList?.selection.indexes.first,
            let firstSelectedTask = taskList?.task(at: firstSelectedIndex)
        {
            taskList?.selection.remove(firstSelectedTask)
            
            if let nextEditingIndex = taskList?.selection.indexes.first
            {
                startEditing(at: nextEditingIndex)
            }
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
    
    private func createNewTask(at index: Int? = nil,
                               createContainer: Bool = false)
    {
        if createContainer && taskList?.selection.count ?? 0 > 1
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
        guard let groupIndex = taskList?.groupSelectedTasks() else { return }
        
        startEditing(at: groupIndex)
    }
    
    private func createTask(at index: Int?)
    {
        let newTask = Task()
        
        if let indexOfNewTask = taskList?.add(newTask, at: index)
        {
            taskList?.selection.setTasks(at: [indexOfNewTask])
            
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
        
        taskList.selection.add(task)
        
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
        let selection = taskList?.selection.indexes ?? []
        
        guard selection.max() ?? 0 < tableView.numberOfRows else { return }
        
        tableView.selectRowIndexes(IndexSet(selection),
                                   byExtendingSelection: false)
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return 36
    }
    
    func tableView(_ tableView: NSTableView,
                   rowViewForRow row: Int) -> NSTableRowView?
    {
        return TaskListRow(with: taskList?.task(at: row))
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        // Swift.print("selection did change: \(Array(tableView.selectedRowIndexes).description)")
        
        taskList?.selection.setTasks(at: Array(tableView.selectedRowIndexes))
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
            log(warning: "tableColumn has weird or nil identifier: \(tableColumn?.identifier ?? NSUserInterfaceItemIdentifier(rawValue: "nil"))")
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

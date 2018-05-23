import AppKit
import PureLayout
import SwiftObserver
import SwiftyToolz

class SelectableListView: NSView, NSTableViewDelegate, NSTableViewDataSource, Observer, Observable
{
    // MARK: - Life Cycle
    
    init(with list: SelectableList)
    {
        super.init(frame: NSRect.zero)
        
        // list
        
        self.list = list
        
        observe(list)
        {
            [weak self] in
            
            self?.didReceive($0)
        }
        
        // title
        
        headerView.set(title: list.title.latestUpdate)
        
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.headerView.set(title: newTitle)
        }
        
        // auto layout
        
        translatesAutoresizingMaskIntoConstraints = false
        
        scrollView.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero, excludingEdge: .top)
        scrollView.autoPinEdge(.top,
                               to: .bottom,
                               of: headerView,
                               withOffset: 10 - (Float.verticalGap.cgFloat / 2))
        
        constrainHeaderView()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
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
    
    lazy var tableView: Table =
    {
        let view = Table()
        
        let column = NSTableColumn(identifier:  TaskView.uiIdentifier)
        
        view.addTableColumn(column)
        
        view.allowsMultipleSelection = true
        view.backgroundColor = NSColor.clear
        view.headerView = nil
    
        view.dataSource = self
        view.delegate = self
        view.intercellSpacing = NSSize(width: 0,
                                       height: Float.verticalGap.cgFloat)
        
        return view
    }()
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        
        send(.wantsFocus)
    }
    
    // MARK: - Keyboard Input
    
    override func keyDown(with event: NSEvent)
    {
        //Swift.print("key own. code: \(event.keyCode) characters: <\(event.characters ?? "nil")>")
     
        //interpretKeyEvents([event])
        
        let cmd = event.cmd
     
        switch event.key
        {
        case .enter:
            let numSelections = list?.selection.count ?? 0
            
            if numSelections == 0
            {
                createNewTask()
            }
            else if numSelections == 1
            {
                if cmd
                {
                    if let index = list?.selection.indexes.first
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
                    if let index = list?.selection.indexes.first
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
                list?.checkOffFirstSelectedUncheckedTask()
                loadSelectionFromTaskList()
            }
            else { deleteSelectedTasks() }
            
        case .left: send(.wantsToPassFocusLeft)
            
        case .right: send(.wantsToPassFocusRight)
            
        case .down: if cmd { list?.moveSelectedTask(1) }
            
        case .up: if cmd { list?.moveSelectedTask(-1) }
            
        case .unknown: didPress(key: event.characters, with: cmd)
        }
    }
    
    private func didPress(key: String?, with cmd: Bool)
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
            else
            {
                list?.debug()
            }
        case "n": if cmd { createNewTask(createContainer: true) }
        case "t": store.root.debug()
        default: break
        }
    }
    
    // MARK: - Process List Events
    
    private func didReceive(_ edit: ListEdit)
    {
        //Swift.print("list view <\(titleField.stringValue)> \(change)")
        
        switch edit
        {
        case .didInsert(let indexes):
            didInsertSubtask(at: indexes)
            
        case .didRemove(_, let indexes):
            didDeleteSubtasks(at: indexes)
            
        case .didMove(let from, let to):
            didMoveSubtask(from: from, to: to)
            
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
    
    func didMoveSubtask(from: Int, to: Int)
    {
        tableView.beginUpdates()
        tableView.moveRow(at: from, to: to)
        tableView.endUpdates()
    }
    
    // MARK: - Editing the List
    
    private func deleteSelectedTasks()
    {
        guard list?.removeSelectedTasks() ?? false else
        {
            return
        }
        
        loadSelectionFromTaskList()
    }
    
    private func createNewTask(at index: Int? = nil,
                               createContainer: Bool = false)
    {
        if createContainer && list?.selection.count ?? 0 > 1
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
        guard let groupIndex = list?.groupSelectedTasks() else { return }
        
        loadSelectionFromTaskList()
        startEditing(at: groupIndex)
    }
    
    private func createTask(at index: Int?)
    {
        let newTask = Task()
        
        let newIndex: Int? =
        {
            if let index = index
            {
                return list?.insert(newTask, at: index)
            }
            else
            {
                return list?.insertBelowSelection(newTask)
            }
        }()
        
        if let newIndex = newIndex
        {
            loadSelectionFromTaskList()
            startEditing(at: newIndex)
        }
    }
    
    private func startEditing(at index: Int)
    {
        guard index < tableView.numberOfRows else { return }
       
        if index == 0
        {
            jumpToTop()
        }
        else
        {
            tableView.scrollRowToVisible(index)
        }
        
        if let cell = tableView.view(atColumn: 0,
                                     row: index,
                                     makeIfNecessary: false) as? TaskView
        {
            cell.editTitle()
        }
    }
    
    func jumpToTop()
    {
        var newOrigin = scrollView.contentView.bounds.origin
        
        newOrigin.y = 0
        
        scrollView.contentView.setBoundsOrigin(newOrigin)
    }
    
    // MARK: - Table View Delegate
    
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat
    {
        return Float.itemHeight.cgFloat
    }
    
    func tableView(_ tableView: NSTableView,
                   rowViewForRow row: Int) -> NSTableRowView?
    {
        guard let task = list?.task(at: row) else
        {
            log(error: "No task exists for table row \(row).")
            return nil
        }
        
        return Row(with: task)
    }
    
    // MARK: - Table View Data Source
    
    func numberOfRows(in tableView: NSTableView) -> Int
    {
        return list?.numberOfTasks ?? 0
    }
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        let taskViewReuseIdentifier = TaskView.uiIdentifier
        
        guard tableColumn?.identifier == taskViewReuseIdentifier else
        {
            log(warning: "tableColumn has weird or nil identifier: \(tableColumn?.identifier ?? NSUserInterfaceItemIdentifier(rawValue: "nil"))")
            return nil
        }
        
        // FIXME: differentiate reusing and creating cells
        let cell = tableView.makeView(withIdentifier: TaskView.uiIdentifier,
                                  owner: self) as? TaskView ?? TaskView()
        
        if let task = list?.task(at: row)
        {
            cell.configure(with: task)
        }
        
        stopObserving(cell) // FIXME: not necessary when observing only newly created cells... but: stop observing when cells are being removed fro tableView (delegate method?)
        
        observe(cell)
        {
            [weak self, weak cell] event in
            
            switch event
            {
            case .didEditTitle: self?.taskViewDidEndEditing(cell)
            case .willContainFirstResponder: self?.send(.wantsFocus)
            case .didNothing: break
            }
        }
        
        return cell
    }
    
    private func taskViewDidEndEditing(_ taskView: TaskView?)
    {
        guard let taskView = taskView else { return }
        
        if list?.selection.count ?? 0 > 1,
            let firstSelectedIndex = list?.selection.indexes.first,
            tableView.row(for: taskView) == firstSelectedIndex,
            let firstSelectedTask = taskView.task
        {
            list?.selection.remove(tasks: [firstSelectedTask])
            
            loadSelectionFromTaskList()
            
            if let nextEditingIndex = list?.selection.indexes.first
            {
                startEditing(at: nextEditingIndex)
            }
        }
    }
    
    // MARK: - Selection
    
    func loadSelectionFromTaskList()
    {
        let selection = list?.selection.indexes ?? []
        
        guard selection.max() ?? 0 < tableView.numberOfRows else { return }
        
        tableView.selectRowIndexes(IndexSet(selection),
                                   byExtendingSelection: false)
    }
    
        // table view delegate
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        // Swift.print("selection did change: \(Array(tableView.selectedRowIndexes).description)")
        
        list?.selection.setWithTasksListed(at: Array(tableView.selectedRowIndexes))
    }
    
    // MARK: - Header View
    
    private func constrainHeaderView()
    {
        headerView.autoPinEdge(toSuperviewEdge: .left)
        headerView.autoPinEdge(toSuperviewEdge: .right)
        headerView.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        headerView.autoSetDimension(.height,
                                    toSize: Float.itemHeight.cgFloat)
    }
    
    private lazy var headerView: Header =
    {
        let view = Header()
        self.addSubview(view)
        
        return view
    }()
    
    // MARK: - Task List
    
    private(set) weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: NavigationRequest { return .wantsNothing }
    
    enum NavigationRequest
    {
        case wantsNothing
        case wantsToPassFocusRight
        case wantsToPassFocusLeft
        case wantsFocus
    }
}

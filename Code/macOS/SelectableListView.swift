import AppKit
import PureLayout
import SwiftObserver
import SwiftyToolz

class SelectableListView: NSView, NSTableViewDelegate, Observer, Observable
{
    // MARK: - Life Cycle
    
    init(with list: SelectableList)
    {
        super.init(frame: NSRect.zero)
        
        source.list = list
        
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
        
        constrainHeaderView()
        constrainScrollView()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Mouse Input
    
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
                loadUISelectionFromList()
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
                scrollView.tableView.reloadData()
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
        scrollView.tableView.beginUpdates()
        scrollView.tableView.removeRows(at: IndexSet(indexes),
                             withAnimation: NSTableView.AnimationOptions.slideUp)
        scrollView.tableView.endUpdates()
    }
    
    func didInsertSubtask(at indexes: [Int])
    {
        scrollView.tableView.beginUpdates()
        scrollView.tableView.insertRows(at: IndexSet(indexes),
                             withAnimation: NSTableView.AnimationOptions.slideDown)
        scrollView.tableView.endUpdates()
    }
    
    func didMoveSubtask(from: Int, to: Int)
    {
        scrollView.tableView.beginUpdates()
        scrollView.tableView.moveRow(at: from, to: to)
        scrollView.tableView.endUpdates()
    }
    
    // MARK: - Editing the List
    
    private func deleteSelectedTasks()
    {
        guard list?.removeSelectedTasks() ?? false else
        {
            return
        }
        
        loadUISelectionFromList()
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
        
        loadUISelectionFromList()
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
            loadUISelectionFromList()
            startEditing(at: newIndex)
        }
    }
    
    private func startEditing(at index: Int)
    {
        guard index < scrollView.tableView.numberOfRows else { return }
       
        if index == 0
        {
            jumpToTop()
        }
        else
        {
            scrollView.tableView.scrollRowToVisible(index)
        }
        
        if let cell = scrollView.tableView.view(atColumn: 0,
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
    
    func tableView(_ tableView: NSTableView,
                   heightOfRow row: Int) -> CGFloat
    {
        return Float.itemHeight.cgFloat
    }
    
    func tableView(_ tableView: NSTableView,
                   viewFor tableColumn: NSTableColumn?,
                   row: Int) -> NSView?
    {
        return source.tableView(tableView,
                                    viewFor: tableColumn,
                                    row: row)
    }
    
    func tableView(_ tableView: NSTableView,
                   rowViewForRow row: Int) -> NSTableRowView?
    {
        return source.tableView(tableView,
                                rowViewForRow: row)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        storeUISelectionInList()
    }
    
    // MARK: - Creating Task Views
    
    lazy var source: TableDataSource =
    {
        let src = TableDataSource()
        
        observe(src)
        {
            [unowned self] event in
            
            if case .didCreate(let taskView) = event
            {
                self.observe(taskView: taskView)
            }
        }
        
        return src
    }()
    
    private func observe(taskView: TaskView)
    {
        observe(taskView)
        {
            [weak self, weak taskView] event in
            
            switch event
            {
            case .didNothing: break
            case .didEditTitle: self?.editTitleOfNextSelectedTask(in: taskView)
            case .willContainFirstResponder: self?.send(.wantsFocus)
            case .willDeinit: self?.stopObserving(taskView)
            }
        }
    }
    
    // MARK: - Editing
    
    private func editTitleOfNextSelectedTask(in taskView: TaskView?)
    {
        guard let taskView = taskView else { return }
        
        if list?.selection.count ?? 0 > 1,
            let firstSelectedIndex = list?.selection.indexes.first,
            scrollView.tableView.row(for: taskView) == firstSelectedIndex,
            let firstSelectedTask = taskView.task
        {
            list?.selection.remove(tasks: [firstSelectedTask])
            
            loadUISelectionFromList()
            
            if let nextEditingIndex = list?.selection.indexes.first
            {
                startEditing(at: nextEditingIndex)
            }
        }
    }
    
    // MARK: - Manage Selection
    
    func loadUISelectionFromList()
    {
        let selection = list?.selection.indexes ?? []
        
        guard selection.max() ?? 0 < scrollView.tableView.numberOfRows else { return }
        
        scrollView.tableView.selectRowIndexes(IndexSet(selection),
                                   byExtendingSelection: false)
    }
    
    private func storeUISelectionInList()
    {
        let selectedIndexes = Array(scrollView.tableView.selectedRowIndexes)
        
        list?.selection.setWithTasksListed(at: selectedIndexes)
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
    
    // MARK: - Scroll View
    
    private func constrainScrollView()
    {
        scrollView.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                excludingEdge: .top)
        
        let halfVerticalGap = Float.verticalGap.cgFloat / 2
        
        scrollView.autoPinEdge(.top,
                               to: .bottom,
                               of: headerView,
                               withOffset: 10 - halfVerticalGap)
    }
    
    private lazy var scrollView: ScrollingTable =
    {
        let view = ScrollingTable.newAutoLayout()
        self.addSubview(view)

        view.tableView.dataSource = source
        view.tableView.delegate = self
        
        return view
    }()
    
    // MARK: - Table View
    
    func makeTableFirstResponder() -> Bool
    {
        return NSApp.mainWindow?.makeFirstResponder(scrollView.tableView) ?? false
    }
    
    // MARK: - List
    
    private(set) weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: Table.NavigationRequest { return .wantsNothing }
}

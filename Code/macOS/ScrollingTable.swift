import AppKit
import SwiftObserver

class ScrollingTable: NSScrollView, NSTableViewDelegate, Observer, Observable 
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: NSZeroRect)
        
        documentView = tableView
        drawsBackground = false
        automaticallyAdjustsContentInsets = false
        contentInsets = NSEdgeInsets(top: 0, left: 0, bottom: 10, right: 0)
    }
    
    required init?(coder: NSCoder) { fatalError() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        self.list = list
        source.list = list
        tableView.configure(with: list)
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
        return source.tableView(tableView, rowViewForRow: row)
    }
    
    func tableViewSelectionDidChange(_ notification: Notification)
    {
        tableView.storeUISelectionInList()
    }
    
    // MARK: - Editing
    
    func editTitleOfNextSelectedTask(in taskView: TaskView?)
    {
        guard let taskView = taskView else { return }
        
        if list?.selection.count ?? 0 > 1,
            let firstSelectedIndex = list?.selection.indexes.first,
            tableView.row(for: taskView) == firstSelectedIndex,
            let firstSelectedTask = taskView.task
        {
            list?.selection.remove(tasks: [firstSelectedTask])
            
            tableView.loadUISelectionFromList()
            
            if let nextEditingIndex = list?.selection.indexes.first
            {
                startEditing(at: nextEditingIndex)
            }
        }
    }
    
    func deleteSelectedTasks()
    {
        guard list?.removeSelectedTasks() ?? false else { return }
        
        tableView.loadUISelectionFromList()
    }
    
    func createNewTask(at index: Int? = nil, createGroup: Bool = false)
    {
        if createGroup && list?.selection.count ?? 0 > 1
        {
            groupSelectedTasks()
        }
        else
        {
            createTask(at: index)
        }
    }
    
    func groupSelectedTasks()
    {
        guard let groupIndex = list?.groupSelectedTasks() else { return }
        
        tableView.loadUISelectionFromList()
        startEditing(at: groupIndex)
    }
    
    func createTask(at index: Int?)
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
            tableView.loadUISelectionFromList()
            startEditing(at: newIndex)
        }
    }
    
    func startEditing(at index: Int)
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
        var newOrigin = contentView.bounds.origin
        
        newOrigin.y = 0
        
        contentView.setBoundsOrigin(newOrigin)
    }
    
    // MARK: - Creating Task Views
    
    lazy var source: TableSource =
    {
        let src = TableSource()
        
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
    
    // MARK: - Table View
    
    lazy var tableView: Table =
    {
        let view = Table.newAutoLayout()
        
        view.delegate = self
        view.dataSource = source
        
        return view
    }()
    
    // MARK: - List
    
    private weak var list: SelectableList?

    // MARK: - Observability
    
    var latestUpdate: Table.NavigationRequest { return .wantsNothing }
}

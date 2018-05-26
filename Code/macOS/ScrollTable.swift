import AppKit
import SwiftObserver
import SwiftyToolz

class ScrollTable: NSScrollView, NSTableViewDelegate, Observer, Observable 
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: NSZeroRect)
        
        tableView.delegate = self
        tableView.dataSource = source
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
        
        source.configure(with: list)
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
        tableView.selectionDidChange()
    }
    
    // MARK: - Creating Task Views
    
    private lazy var source: TableSource =
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
            case .willContainFirstResponder: self?.send(.wantsToBeRevealed)
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
            tableView.row(for: taskView) == firstSelectedIndex,
            let firstSelectedTask = taskView.task
        {
            list?.selection.remove(tasks: [firstSelectedTask])
            
            if let nextEditingIndex = list?.selection.indexes.first
            {
                tableView.editTitle(at: nextEditingIndex)
            }
        }
    }
    
    func createTask(at index: Int? = nil, group: Bool = false)
    {
        if group && list?.selection.count ?? 0 > 1
        {
            list?.groupSelectedTasks()
        }
        else
        {
            createTask(at: index)
        }
    }
    
    private func createTask(at index: Int?)
    {
        if let index = index
        {
            list?.create(at: index)
        }
        else
        {
            list?.createBelowSelection()
        }
    }
    
    private func jumpToTop()
    {
        var newOrigin = contentView.bounds.origin
        
        newOrigin.y = 0
        
        contentView.setBoundsOrigin(newOrigin)
    }
    
    // MARK: - Basics
    
    let tableView = Table.newAutoLayout()
    
    private weak var list: SelectableList?

    // MARK: - Observability
    
    var latestUpdate: NavigationRequest { return .wantsNothing }
    
    enum NavigationRequest
    {
        case wantsNothing
        case wantsToPassFocusRight
        case wantsToPassFocusLeft
        case wantsToBeRevealed
    }
    
    // MARK: - Forward Input
    
    override func keyDown(with event: NSEvent)
    {
        nextResponder?.keyDown(with: event)
    }
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        nextResponder?.mouseDown(with: event)
    }
}

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
    
    // MARK: - Creating & Observing Task Views
    
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
            
            self?.didReceive(event, from: taskView)
        }
    }
    
    private func didReceive(_ event: TaskView.Event,
                            from taskView: TaskView?)
    {
        switch event
        {
        case .didNothing: break
        case .didEditTitle: tableView.editTitleOfNextSelectedTaskView()
        case .willContainFirstResponder: send(.wantsToBeRevealed)
        case .willDeinit: stopObserving(taskView)
        }
    }
    
    // MARK: - Basics
    
    let tableView = Table.newAutoLayout()
    
    private weak var list: SelectableList?

    // MARK: - Observability
    
    var latestUpdate: NavigationRequest { return .wantsNothing }
    
    enum NavigationRequest
    {
        case wantsNothing
        case wantsToBeRevealed
    }
    
    // MARK: - Forward Mouse Clicks
    // FIXME: still needed??
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        nextResponder?.mouseDown(with: event)
    }
}

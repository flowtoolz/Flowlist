import AppKit
import PureLayout
import SwiftObserver
import SwiftyToolz

class SelectableListView: NSView, Observer, Observable
{
    // MARK: - Life Cycle
    
    init(with list: SelectableList)
    {
        super.init(frame: NSRect.zero)
        translatesAutoresizingMaskIntoConstraints = false
        
        // propagate list down
        self.list = list
        scrollView.configure(with: list)
        
        // title
        headerView.set(title: list.title.latestUpdate)
        
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.headerView.set(title: newTitle)
        }
        
        // auto layout
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
                scrollView.createNewTask()
            }
            else if numSelections == 1
            {
                if cmd
                {
                    if let index = list?.selection.indexes.first
                    {
                        scrollView.startEditing(at: index)
                    }
                }
                else
                {
                    scrollView.createNewTask()
                }
            }
            else
            {
                if cmd
                {
                    if let index = list?.selection.indexes.first
                    {
                        scrollView.startEditing(at: index)
                    }
                }
                else
                {
                    scrollView.createNewTask(createGroup: true)
                }
            }
            
        case .space: scrollView.createTask(at: 0)
            
        case .delete:
            if cmd
            {
                list?.checkOffFirstSelectedUncheckedTask()
                scrollView.tableView.loadSelectionFromList()
            }
            else { scrollView.deleteSelectedTasks() }
            
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
        case "n": if cmd { scrollView.createNewTask(createGroup: true) }
        case "t": store.root.debug()
        default: break
        }
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
    
    lazy var scrollView: ScrollingTable =
    {
        let view = ScrollingTable.newAutoLayout()
        self.addSubview(view)
        
        observe(view) { [weak self] in self?.send($0) }
        
        return view
    }()
    
    // MARK: - List
    
    private(set) weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: ScrollingTable.NavigationRequest { return .wantsNothing }
}

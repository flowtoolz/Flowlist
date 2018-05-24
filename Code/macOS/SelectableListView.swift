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
        scrollTable.configure(with: list)
        
        // title
        header.set(title: list.title.latestUpdate)
        
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.header.set(title: newTitle)
        }
        
        // auto layout
        constrainHeader()
        constrainScrollTable()
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
                scrollTable.createTask()
            }
            else if numSelections == 1
            {
                if cmd
                {
                    if let index = list?.selection.indexes.first
                    {
                        scrollTable.editTitle(at: index)
                    }
                }
                else
                {
                    scrollTable.createTask()
                }
            }
            else
            {
                if cmd
                {
                    if let index = list?.selection.indexes.first
                    {
                        scrollTable.editTitle(at: index)
                    }
                }
                else
                {
                    scrollTable.createTask(group: true)
                }
            }
            
        case .space: scrollTable.createTask(at: 0)
            
        case .delete:
            if cmd
            {
                list?.checkOffFirstSelectedUncheckedTask()
                scrollTable.tableView.loadSelectionFromList()
            }
            else { scrollTable.removeSelectedTasks() }
            
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
                scrollTable.tableView.reloadData()
            }
            else
            {
                list?.debug()
            }
        case "t": store.root.debug()
        default: break
        }
    }
    
    // MARK: - Header
    
    private func constrainHeader()
    {
        header.autoPinEdge(toSuperviewEdge: .left)
        header.autoPinEdge(toSuperviewEdge: .right)
        header.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        header.autoSetDimension(.height, toSize: Float.itemHeight.cgFloat)
    }
    
    private lazy var header: Header =
    {
        let view = Header()
        self.addSubview(view)
        
        return view
    }()
    
    // MARK: - Scroll Table
    
    private func constrainScrollTable()
    {
        scrollTable.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                excludingEdge: .top)
        
        let halfVerticalGap = Float.verticalGap.cgFloat / 2
        
        scrollTable.autoPinEdge(.top,
                               to: .bottom,
                               of: header,
                               withOffset: 10 - halfVerticalGap)
    }
    
    lazy var scrollTable: ScrollTable =
    {
        let view = ScrollTable.newAutoLayout()
        self.addSubview(view)
        
        observe(view) { [weak self] in self?.send($0) }
        
        return view
    }()
    
    // MARK: - List
    
    private(set) weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: ScrollTable.NavigationRequest { return .wantsNothing }
}

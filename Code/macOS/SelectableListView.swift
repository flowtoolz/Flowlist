import AppKit
import PureLayout
import SwiftObserver
import SwiftyToolz

class SelectableListView: NSView, Observer, Observable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainHeader()
        constrainScrollTable()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        stopObserving(self.list?.title)
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.header.set(title: newTitle)
        }
        
        self.list = list
        
        header.set(title: list.title.latestUpdate)
        scrollTable.configure(with: list)
    }
    
    // MARK: - Mouse Input
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        
        send(.wantsToBeRevealed)
    }
    
    // MARK: - Keyboard Input
    
    override func keyDown(with event: NSEvent)
    {   
        //Swift.print("key own. code: \(event.keyCode) characters: <\(event.characters ?? "nil")>")
     
        switch event.key
        {
        case .enter:
            let numSelections = list?.selection.count ?? 0
            
            if numSelections > 0, event.cmd
            {
                if let index = list?.selection.indexes.first
                {
                    scrollTable.tableView.editTitle(at: index)
                }
                
                break
            }
            
            if numSelections < 2
            {
               list?.createBelowSelection()
            }
            else
            {
                list?.groupSelectedTasks()
            }
            
        case .space: list?.create(at: 0)
            
        case .delete:
            if event.cmd
            {
                list?.checkOffFirstSelectedUncheckedTask()
            }
            else
            {
                _ = list?.removeSelectedTasks()
            }
            
        case .left: send(.wantsToPassFocusLeft)
            
        case .right: send(.wantsToPassFocusRight)
            
        case .down: if event.cmd { list?.moveSelectedTask(1) }
            
        case .up: if event.cmd { list?.moveSelectedTask(-1) }
            
        case .tab, .unknown: if event.characters == "t" { store.root.debug() }
        }
        
        nextResponder?.keyDown(with: event)
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

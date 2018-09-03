import AppKit
import PureLayout
import UIToolz
import SwiftObserver
import SwiftyToolz

class SelectableListView: LayerBackedView, Observer, Observable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
    
        backgroundColor = .background
        setItemBorder()
        constrainHeader()
        constrainScrollTable()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        header.configure(with: list)
        
        scrollTable.configure(with: list)
        
        stopObserving(self.list)
        observe(list) { [weak self] in self?.didReceive($0) }
        
        isHidden = list.root == nil
        
        self.list = list
    }
    
    private func didReceive(_ event: List.Event)
    {
        guard case .did(let edit) = event,
            case .changeRoot(let old, let new) = edit else
        {
            return
        }
        
        isHidden = new == nil
        
        stopObserving(old?.state)
        
        if let newRoot = new
        {
            observe(newRoot.state)
            {
                [weak self, weak newRoot] _ in
                
                guard let root = newRoot else { return }
                
                self?.header.update(with: root)
            }
            
            header.update(with: newRoot)
        }
    }
    
    // MARK: - Mouse Input
    
    override func mouseDown(with event: NSEvent)
    {
        super.mouseDown(with: event)
        
        send(.didReceiveUserInput)
    }
    
    // MARK: - Header
    
    private func constrainHeader()
    {
        header.autoPinEdge(toSuperviewEdge: .left)
        header.autoPinEdge(toSuperviewEdge: .right)
        header.autoPinEdge(toSuperviewEdge: .top)
        headerHeightConstraint = header.autoSetDimension(.height,
                                                         toSize: TaskView.heightWithSingleLine)
    }
    
    private lazy var header: Header = addForAutoLayout(Header())
    
    // MARK: - Scroll Table
    
    func fontSizeDidChange()
    {
        updateLayoutConstants()
        
        scrollTable.table.fontSizeDidChange()
    }
    
    private func constrainScrollTable()
    {
        let gap = TaskView.spacing + 1
        let insets = NSEdgeInsets(top: 0,
                                  left: gap,
                                  bottom: gap,
                                  right: gap)

        let constraints = scrollTable.autoPinEdgesToSuperviewEdges(with: insets,
                                                                   excludingEdge: .top)
        scrollTableInsetConstraints = constraints
        
        scrollTableTopConstraint = scrollTable.autoPinEdge(.top,
                                                           to: .bottom,
                                                           of: header,
                                                           withOffset: scrollTableTopOffset)
    }
    
    func didEndResizing()
    {
        scrollTable.table.didEndResizing()
    }
    
    private(set) lazy var scrollTable: ScrollTable =
    {
        let scrollView = addForAutoLayout(ScrollTable())
        
        observe(scrollView.table, select: .willEditTitle)
        {
            [weak self] in self?.send(.didReceiveUserInput)
        }
        
        return scrollView
    }()
    
    // MARK: - Dynamic Layout Constants
    
    private func updateLayoutConstants()
    {
        headerHeightConstraint?.constant = TaskView.heightWithSingleLine
        
        let inset = TaskView.spacing + 1
        
        for constraint in scrollTableInsetConstraints
        {
            constraint.constant = constraint.constant < 0 ? -inset : inset
        }
        
        scrollTableTopConstraint?.constant = scrollTableTopOffset
    }
    
    private var headerHeightConstraint: NSLayoutConstraint?
    private var scrollTableTopConstraint: NSLayoutConstraint?
    private var scrollTableInsetConstraints = [NSLayoutConstraint]()
    
    private var scrollTableTopOffset: CGFloat
    {
        let spacing = TaskView.spacing
        let smallHalfItemSpacing = CGFloat(Int(spacing / 2))
        return spacing - smallHalfItemSpacing
    }
    
    // MARK: - List
    
    private(set) weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didReceiveUserInput }
}

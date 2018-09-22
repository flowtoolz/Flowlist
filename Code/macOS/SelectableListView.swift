import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class SelectableListView: LayerBackedView, Observer, Observable
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
        let height = TaskView.heightWithSingleLine
        headerHeightConstraint = header.constrainHeight(to: height)
        headerTopConstraint = header.constrainTopToParent(inset: TaskView.spacing)
        
        header.constrainLeftToParent()
        header.constrainRightToParent()
    }
    
    private lazy var header = addForAutoLayout(Header())
    
    // MARK: - Scroll Table
    
    func fontSizeDidChange()
    {
        updateLayoutConstants()
        
        scrollTable.table.fontSizeDidChange()
    }
    
    private func constrainScrollTable()
    {
        let gap = TaskView.spacing

        let stic = scrollTable.constrainToParentExcludingTop(insetLeft: gap,
                                                             insetBottom: gap,
                                                             insetRight: gap)
        
        scrollTableInsetConstraints = stic
        
        scrollTableTopConstraint = scrollTable.constrain(below: header,
                                                         gap: scrollTableTopOffset)
    }
    
    func didEndResizing()
    {
        scrollTable.table.didEndResizing()
    }
    
    private(set) lazy var scrollTable: ScrollTable =
    {
        let scrollView = addForAutoLayout(ScrollTable())
        
        observe(scrollView.table)
        {
            [weak self] event in
            
            switch event
            {
            case .willEditTitle, .wasClicked:
                self?.send(.didReceiveUserInput)
                
            default: break
            }
        }
        
        return scrollView
    }()
    
    // MARK: - Dynamic Layout Constants
    
    private func updateLayoutConstants()
    {
        let spacing = TaskView.spacing
        
        headerTopConstraint?.constant = spacing
        headerHeightConstraint?.constant = TaskView.heightWithSingleLine
        
        for constraint in scrollTableInsetConstraints
        {
            constraint.constant = constraint.constant < 0 ? -spacing : spacing
        }
        
        scrollTableTopConstraint?.constant = scrollTableTopOffset
    }
    
    private var headerTopConstraint: NSLayoutConstraint?
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

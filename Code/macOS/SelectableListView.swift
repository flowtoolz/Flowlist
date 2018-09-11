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
        header.constrainLeft(to: self)
        header.constrainRight(to: self)
        header.constrainTop(to: self)
        headerHeightConstraint = header.constrainHeight(to: TaskView.heightWithSingleLine)
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

        scrollTableInsetConstraints.removeAll()
        scrollTableInsetConstraints.append(scrollTable.constrainLeft(to: self,
                                                                     offset: gap))
        scrollTableInsetConstraints.append(scrollTable.constrainRight(to: self,
                                                                      offset: -gap))
        scrollTableInsetConstraints.append(scrollTable.constrainBottom(to: self,
                                                                       offset: -gap))
        
        scrollTableTopConstraint = scrollTable.constrain(below: header,
                                                         offset: scrollTableTopOffset)
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

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
        
        backgroundColor = Color.background
        layer?.cornerRadius = Float.cornerRadius.cgFloat
        setItemBorder()
        
        constrainHeader()
        constrainScrollTable()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    func didEndResizing()
    {
        scrollTable.table.didEndResizing()
    }
    
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
        header.autoPinEdge(toSuperviewEdge: .left, withInset: 1)
        header.autoPinEdge(toSuperviewEdge: .right, withInset: 1)
        header.autoPinEdge(toSuperviewEdge: .top, withInset: 1)
        header.autoSetDimension(.height, toSize: Float.itemHeight.cgFloat)
    }
    
    private lazy var header: Header = addForAutoLayout(Header())
    
    // MARK: - Scroll Table
    
    private func constrainScrollTable()
    {
        let gap = Float.verticalGap.cgFloat + 1
        let insets = NSEdgeInsets(top: 0,
                                  left: gap,
                                  bottom: gap,
                                  right: gap)

        scrollTable.autoPinEdgesToSuperviewEdges(with: insets, excludingEdge: .top)
        scrollTable.autoPinEdge(.top, to: .bottom, of: header)
    }
    
    lazy var scrollTable: ScrollTable =
    {
        let scrollView = addForAutoLayout(ScrollTable())
        
        observe(scrollView.table, select: .willEditTitle)
        {
            [weak self] in self?.send(.didReceiveUserInput)
        }
        
        return scrollView
    }()
    
    // MARK: - List
    
    private(set) weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didReceiveUserInput }
}

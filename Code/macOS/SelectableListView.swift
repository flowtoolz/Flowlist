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
        
        constrainHeader()
        constrainScrollTable()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Configuration
    
    func configure(with list: SelectableList)
    {
        // header
        stopObserving(self.list?.title)
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.header.set(title: newTitle)
        }
        
        header.set(title: list.title.latestUpdate)
        
        // scroll table
        scrollTable.configure(with: list)
        
        // list
        stopObserving(self.list)
        observe(list)
        {
            [weak self] event in
            
            if case .didChangeRoot(_, let new) = event
            {
                self?.isHidden = new == nil
            }
        }
        
        isHidden = list.root == nil
        
        self.list = list
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
        header.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        header.autoSetDimension(.height, toSize: Float.itemHeight.cgFloat)
    }
    
    private lazy var header: Header = addForAutoLayout(Header())
    
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

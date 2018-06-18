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
        // TODO: move this to Header
        // header
        stopObserving(self.list?.title)
        observe(list.title)
        {
            [weak self] newTitle in
            
            self?.header.set(title: newTitle)
        }
        
        header.set(title: list.title.latestUpdate)
        header.showIcon(list.isRootList)
        
        if let root = list.root { header.update(with: root) }
        
        // scroll table
        scrollTable.configure(with: list)
        
        // list
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
        header.autoPinEdge(toSuperviewEdge: .right, withInset: 0.5)
        header.autoPinEdge(toSuperviewEdge: .top, withInset: 10)
        header.autoSetDimension(.height, toSize: Float.itemHeight.cgFloat)
    }
    
    private lazy var header: Header = addForAutoLayout(Header())
    
    // MARK: - Scroll Table
    
    private func constrainScrollTable()
    {
        let insets = NSEdgeInsets(top: 0, left: 0, bottom: 0, right: 0.5)
        
        scrollTable.autoPinEdgesToSuperviewEdges(with: insets,
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

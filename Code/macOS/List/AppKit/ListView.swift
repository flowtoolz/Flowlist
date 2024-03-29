import AppKit
import SwiftUIToolz
import GetLaid
import SwiftObserver
import SwiftyToolz

class ListView: LayerBackedView, SwiftObserver.ObservableObject, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainHeader()
        constrainScrollTable()
    }
    
    required init?(coder decoder: NSCoder) { nil }
    
    // MARK: - Configuration
    
    func configure(with list: List)
    {
        header.configure(with: list)
        
        scrollTable.table.configure(with: list)
        
        stopObserving(self.list)
        observe(list) { [weak self] in self?.didReceive($0) }
        
        isHidden = list.root == nil
        
        self.list = list
    }
    
    private func didReceive(_ event: List.Event)
    {
        guard case .did(let edit) = event,
            case .switchedParent(_, let new) = edit else { return }
        
        isHidden = new == nil
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
        let height = relativeHeaderHeight * ItemView.heightWithSingleLine
        headerHeightConstraint = header.height >> height
        header >> allButBottom
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
        scrollTable >> allButTop
        scrollTable.top >> header.bottom
    }
    
    func didEndResizing()
    {
        scrollTable.table.didEndResizing()
    }
    
    private(set) lazy var scrollTable: ScrollTable<ItemTable> =
    {
        let scrollView = addForAutoLayout(ScrollTable<ItemTable>())
        
        scrollView.drawsBackground = false
        scrollView.automaticallyAdjustsContentInsets = false
        scrollView.contentInsets = NSEdgeInsets(top: 0,
                                                left: 0,
                                                bottom: 10,
                                                right: 0)
        
        observe(scrollView.table)
        {
            [weak self] event in
            
            switch event
            {
            case .willEditText, .wasClicked:
                self?.send(.didReceiveUserInput)
                
            default: break
            }
        }
        
        return scrollView
    }()
    
    // MARK: - Dynamic Layout Constants
    
    private func updateLayoutConstants()
    {
        headerHeightConstraint?.constant = relativeHeaderHeight * ItemView.heightWithSingleLine
    }

    private let relativeHeaderHeight: CGFloat = 1.5
    private var headerHeightConstraint: NSLayoutConstraint?
    
    // MARK: - List
    
    private(set) weak var list: List?
    
    // MARK: - Observable Observer
    
    let messenger = Messenger<Event>()
    enum Event { case didReceiveUserInput }
    let receiver = Receiver()
}

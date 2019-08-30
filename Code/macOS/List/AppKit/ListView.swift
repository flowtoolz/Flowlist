import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class ListView: LayerBackedView, Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        setupShadow()
        observe(darkMode) { [weak self] _ in self?.adjustShadowToColorMode() }
        
        constrainHeader()
        constrainScrollTable()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopObserving() }
    
    // MARK: - Shadow
    
    private func setupShadow()
    {
        shadow = NSShadow()
        layer?.shadowColor = Color.gray(brightness: 0.5).cgColor
        layer?.shadowRadius = 0
        adjustShadowToColorMode()
    }
    
    private func adjustShadowToColorMode()
    {
        let isDark = Color.isInDarkMode
        layer?.shadowOffset = CGSize(width: isDark ? -1 : 1, height: -1)
        layer?.shadowOpacity = isDark ? 0.28 : 0.2
    }
    
    // MARK: - Configuration
    
    func configure(with list: List)
    {
        header.configure(with: list)
        
        scrollTable.table.configure(with: list)
        
        stopObserving(self.list)
        observe(list).unwrap() { [weak self] in self?.didReceive($0) }
        
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
        headerHeightConstraint = header.constrainHeight(to: height)
        header.constrainToParentExcludingBottom()
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
        scrollTable.constrainToParentExcludingTop()
        
        scrollTable.constrain(below: header)
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
        
        observe(scrollView.table).unwrap()
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
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Event?
    enum Event { case didReceiveUserInput }
}

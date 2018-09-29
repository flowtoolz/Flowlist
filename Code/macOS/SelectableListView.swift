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
        
        shadow = NSShadow()
        layer?.shadowColor = Color.gray(brightness: 0.5).cgColor
        layer?.shadowOffset = CGSize(width: Color.isInDarkMode ? -1 : 1,
                                     height: -1)
        layer?.shadowRadius = 0
        layer?.shadowOpacity = Color.isInDarkMode ? 0.28 : 0.2
        
        observe(darkMode)
        {
            [weak self] isDark in
            
            self?.layer?.shadowOffset = CGSize(width: isDark ? -1 : 1,
                                               height: -1)
            self?.layer?.shadowOpacity = Color.isInDarkMode ? 0.28 : 0.2
        }
        
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
    
    // MARK: - Change with Browser Moves
    
    func set(visibleForAnimation visible: Bool)
    {
        let shouldBeVisible = visible && list?.root != nil
        
        isHidden = !shouldBeVisible
    }
    
    func set(focused: Bool)
    {
        header.set(focused: focused)
        
        scrollTable.table.isFocused = focused
        
        for index in 0 ..< scrollTable.table.numberOfRows
        {
            if let view = scrollTable.table.view(atColumn: 0,
                                                 row: index,
                                                 makeIfNecessary: false) as? TaskView
            {
                view.set(focused: focused)
            }
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
        let height = relativeHeaderHeight * TaskView.heightWithSingleLine
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
        headerHeightConstraint?.constant = relativeHeaderHeight * TaskView.heightWithSingleLine
    }

    private let relativeHeaderHeight: CGFloat = 1.5
    
    private var headerHeightConstraint: NSLayoutConstraint?
    
    // MARK: - List
    
    private(set) weak var list: SelectableList?
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didReceiveUserInput }
}

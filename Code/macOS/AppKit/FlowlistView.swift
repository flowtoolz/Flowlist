import AppKit
import SwiftUIToolz
import GetLaid
import SwiftObserver
import SwiftyToolz

class FlowlistView: LayerBackedView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainBrowserView(bottomInset: isFullVersion ? 0 : purchaseViewHeight)
        addPurchaseView()
        
        if !isFullVersion
        {
            observe(purchaseView).select(.expandButtonWasClicked)
            {
                [weak self] in self?.togglePurchaseView()
            }
            
            observe(purchaseController).select(.didPurchaseFullVersion)
            {
                [weak self] in self?.didPurchaseFullVersion()
            }
        }
        
        // For making screen shots and screen recordings
        //        #if DEBUG
        //        isFullVersion = true
        //        view.layer?.backgroundColor = NSColor.black.cgColor
        //        browserView.constrainWidth(to: 960)
        //        browserView.constrainHeight(to: 540)
        //        browserView.constrainCenter(to: view)
        //        return
        //        #endif
    }
    
    required init?(coder decoder: NSCoder) { nil }
    
    // MARK: - Key Events
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool
    {
        // just so this goes directly to the menu
        if event.type == .keyDown && event.key == .enter { return false }
        
        return super.performKeyEquivalent(with: event)
    }
    
    // MARK: - Purchase View
    
    private func didPurchaseFullVersion()
    {
        guard isFullVersion else { return }
        
        set(purchaseViewHeight: 0)
        {
            self.purchaseView.isHidden = true
            self.browserViewBottomConstraint?.constant = 0
        }
    }
    
    private func togglePurchaseView()
    {
        purchaseView.isExpanded = !purchaseView.isExpanded
        set(purchaseViewHeight: purchaseViewHeight)
    }
    
    private func set(purchaseViewHeight: CGFloat,
                     completionHandler: Action? = nil)
    {
        NSAnimationContext.beginGrouping()
        
        let context = NSAnimationContext.current
        context.allowsImplicitAnimation = true
        context.duration = 0.3
        context.completionHandler = completionHandler
        
        purchaseViewHeightConstraint?.constant = purchaseViewHeight
        layoutSubtreeIfNeeded()
        
        NSAnimationContext.endGrouping()
    }
    
    private func addPurchaseView()
    {
        guard !isFullVersion else { return }
        
        addForAutoLayout(purchaseView) >> allButTop
        purchaseViewHeightConstraint = purchaseView.height >> purchaseViewHeight
    }
    
    private var purchaseViewHeight: CGFloat
    {
        purchaseView.isExpanded ? 360 : purchaseView.collapsedHeight
    }
    
    private var purchaseViewHeightConstraint: NSLayoutConstraint?
    
    private lazy var purchaseView = PurchaseView()
    
    // MARK: - Browser View
    
    private func constrainBrowserView(bottomInset: CGFloat)
    {
        browserView >> allButBottom
        browserViewBottomConstraint = browserView >> bottom.offset(-bottomInset)
    }
    
    func windowDidResize()
    {
        browserView.windowDidResize()
    }
    
    func windowDidEndResizing()
    {
        browserView.windowDidEndResizing()
    }
    
    private lazy var browserView = addForAutoLayout(BrowserView())
    
    private var browserViewBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class ViewController: NSViewController, Observer
{
    override func loadView()
    {
        let visualEffect = NSVisualEffectView()
        visualEffect.blendingMode = .behindWindow
        visualEffect.state = .active
        visualEffect.material = .selection
        
        view = visualEffect
        
        // For making screen shots and screen recordings
//        #if DEBUG
//        isFullVersion = true
//        view.layer?.backgroundColor = NSColor.black.cgColor
//        browserView.autoSetDimensions(to: CGSize(width: 960, height: 540))
//        browserView.autoCenterInSuperview()
//        return
//        #endif
        
        constrainBrowserView()
        
        if !isFullVersion
        {
            constrainPurchaseView()
            
            observe(purchaseView, select: .expandButtonWasClicked)
            {
                [weak self] in self?.togglePurchaseView()
            }
            
            observe(fullVersionPurchaseController, select: .didPurchaseFullVersion)
            {
                [weak self] in self?.didPurchaseFullVersion()
            }
        }
        
        observe(Window.intendedMainWindowSize)
        {
            [weak self] _ in self?.browserView.didEndResizing()
        }
    }
    
    deinit { stopAllObserving() }
    
    // MARK: - Purchase View
    
    private func didPurchaseFullVersion()
    {
        guard isFullVersion else { return }
        
        set(purchaseViewHeight: 0) { self.removePurchaseView() }
    }
    
    private func removePurchaseView()
    {
        view.removeConstraints(view.constraints)
        purchaseView.removeFromSuperview()
        
        constrainBrowserView()
    }
    
    private func togglePurchaseView()
    {
        purchaseView.isExpanded = !purchaseView.isExpanded
        
        set(purchaseViewHeight: purchaseViewHeight)
    }
    
    private func set(purchaseViewHeight: CGFloat,
                     completionHandler: (() -> Void)? = nil)
    {
        NSAnimationContext.beginGrouping()
        
        let context = NSAnimationContext.current
        context.allowsImplicitAnimation = true
        context.duration = 0.3
        context.completionHandler = completionHandler
        
        purchaseViewHeightConstraint?.constant = purchaseViewHeight
        view.layoutSubtreeIfNeeded()
        
        NSAnimationContext.endGrouping()
    }
    
    private func constrainPurchaseView()
    {
        purchaseView.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                  excludingEdge: .top)
        purchaseView.autoPinEdge(.top, to: .bottom, of: browserView)
        
        
        purchaseViewHeightConstraint = purchaseView.autoSetDimension(.height,
                                                                     toSize: purchaseViewHeight)
    }
    
    private var purchaseViewHeight: CGFloat
    {
        return purchaseView.isExpanded ? 360 : purchaseView.collapsedHeight
    }
    
    private var purchaseViewHeightConstraint: NSLayoutConstraint?
    
    private lazy var purchaseView = view.addForAutoLayout(PurchaseView())
    
    // MARK: - Browser View
    
    private func constrainBrowserView()
    {
        let insets = NSEdgeInsets(top: 17, left: 0, bottom: 0, right: 0)
        browserView.autoPinEdgesToSuperviewEdges(with: insets,
                                                 excludingEdge: .bottom)
        
        if isFullVersion
        {
            browserView.autoPinEdge(toSuperviewEdge: .bottom)
        }
    }
    
    private lazy var browserView = view.addForAutoLayout(BrowserView())
}

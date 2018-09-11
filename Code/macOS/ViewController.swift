import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class ViewController: NSViewController, Observer
{
    override func loadView()
    {
        view = LayerBackedView()
        
        // For making screen shots and screen recordings
//        #if DEBUG
//        isFullVersion = true
//        view.layer?.backgroundColor = NSColor.black.cgColor
//        browserView.constrainWidth(to: 960)
//        browserView.constrainHeight(to: 540)
//        browserView.constrainCenter(to: view)
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
        purchaseView.constrainLeft(to: view)
        purchaseView.constrainRight(to: view)
        purchaseView.constrainBottom(to: view)
        purchaseView.constrainTop(toBottomOf: browserView)
        purchaseViewHeightConstraint = purchaseView.constrainHeight(to: purchaseViewHeight)
    }
    
    private var purchaseViewHeight: CGFloat
    {
        return purchaseView.isExpanded ? 360 : purchaseView.collapsedHeight
    }
    
    private var purchaseViewHeightConstraint: NSLayoutConstraint?
    
    private lazy var purchaseView = view.addForAutoLayout(PurchaseView())
    
    // MARK: - Browser View
    
    func didResize()
    {
        browserView.didResize()
    }
    
    private func constrainBrowserView()
    {
        browserView.constrainTop(to: view)
        browserView.constrainLeft(to: view)
        browserView.constrainRight(to: view)
        
        if isFullVersion
        {
            browserView.constrainBottom(to: view)
        }
    }
    
    private lazy var browserView = view.addForAutoLayout(BrowserView())
}

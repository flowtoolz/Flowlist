import AppKit
import UIToolz
import SwiftObserver

class ViewController: NSViewController, Observer
{
    override func loadView()
    {
        view = LayerBackedView()
        
        constrainBrowserView()
        
        if !isFullVersion
        {
            constrainPurchaseView()
            
            observe(purchaseView, select: .expandButtonWasClicked)
            {
                [weak self] in self?.togglePurchaseView()
            }
        }
    }
    
    // MARK: - Purchase View
    
    private func togglePurchaseView()
    {
        purchaseView.isExpanded = !purchaseView.isExpanded
        
        NSAnimationContext.beginGrouping()

        let context = NSAnimationContext.current
        context.allowsImplicitAnimation = true
        context.duration = 0.3
        
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
        return purchaseView.isExpanded ? 350 : purchaseView.collapsedHeight
    }
    
    private var purchaseViewHeightConstraint: NSLayoutConstraint?
    
    private lazy var purchaseView = view.addForAutoLayout(PurchaseView())
    
    // MARK: - Browser View
    
    private func constrainBrowserView()
    {
        browserView.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                 excludingEdge: .bottom)
        
        if isFullVersion
        {
            browserView.autoPinEdge(toSuperviewEdge: .bottom)
        }
    }
    
    private lazy var browserView = view.addForAutoLayout(BrowserView())
}

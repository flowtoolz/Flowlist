import AppKit
import SwiftObserver
import SwiftyToolz

class PriceTag: NSView, Observer
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainPriceLabel()
        
        update()
        
        observe(fullVersionPurchaseController, select: .didLoadFullVersionProduct)
        {
            [weak self] in self?.update()
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Present Data
    
    func update()
    {
        priceLabel.stringValue = fullVersionPurchaseController.fullVersionProduct?.formattedPrice ?? ""
    }
    
    // MARK: - Price Label
    
    private func constrainPriceLabel()
    {
        priceLabel.autoCenterInSuperview()
    }
    
    lazy var priceLabel: Label =
    {
        let label = addForAutoLayout(Label())
        
        label.font = Font.textLarge.nsFont
        
        return label
    }()
    
}

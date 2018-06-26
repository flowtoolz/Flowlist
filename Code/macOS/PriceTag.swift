import AppKit
import SwiftObserver
import SwiftyToolz

class PriceTag: NSView, Observer
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainDiscountPriceLabel()
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
        guard let product = fullVersionPurchaseController.fullVersionProduct else
        {
            return
        }
        
        priceLabel.stringValue = product.formattedPrice ?? ""
        discountPriceLabel.stringValue = product.formattedDiscountPrice ?? ""
    }
    
    // MARK: - Price Label
    
    private func constrainPriceLabel()
    {
        priceLabel.autoPinEdge(toSuperviewEdge: .left)
        priceLabel.autoPinEdge(toSuperviewEdge: .right)
        priceLabel.autoPinEdge(.bottom, to: .top, of: discountPriceLabel)
        priceLabel.autoConstrainAttribute(.lastBaseline, to: .horizontal, of: self)
    }
    
    lazy var priceLabel: Label = addPriceLabel()
    
    // MARK: - Discount Price Label
    
    private func constrainDiscountPriceLabel()
    {
        discountPriceLabel.autoPinEdge(toSuperviewEdge: .left)
        discountPriceLabel.autoPinEdge(toSuperviewEdge: .right)
    }
    
    lazy var discountPriceLabel: Label = addPriceLabel()
    
    private func addPriceLabel() -> Label
    {
        let label = addForAutoLayout(Label())
        
        label.font = Font.textLarge.nsFont
        label.alignment = .center
        
        return label
    }
}

import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class PriceTag: NSView, Observer
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: .zero)
        
        constrainDiscountPriceLabel()
        constrainPriceLabel()
        constrainHeight(to: 90)
        
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
        guard let price = fullVersionPrice,
            let priceLocale = fullVersionPriceLocale else { return }
        
        let appStorePrice = fullVersionFormattedPrice ?? ""
        discountPriceLabel.stringValue = "Introductory Price " + appStorePrice
        
        let discountAvailable = fullVersionPurchaseController.summerDiscountIsAvailable
        
        if discountAvailable
        {
            var roundedPrice = price.intValue
            
            if Double(roundedPrice) < price.doubleValue
            {
                roundedPrice += 1
            }
            
            let roundedPriceNumber = NSDecimalNumber(value: roundedPrice)
            let regularPriceNumber = price.adding(roundedPriceNumber)
            
            let regularPrice = regularPriceNumber.formattedPrice(in: priceLocale) ?? ""
            
            priceLabel.stringValue = regularPrice
        }
        else
        {
            priceLabel.stringValue = appStorePrice
        }

        stroke.isHidden = !discountAvailable
        discountPriceLabel.isHidden = !discountAvailable
    }
    
    // MARK: - Price Label
    
    private func constrainPriceLabel()
    {
        priceLabel.constrainCenterYToParent(offset: -10)
        priceLabel.constrainCenterXToParent()
        
        stroke.constrainCenterY(to: priceLabel, offset: 1)
        stroke.constrainLeft(to: priceLabel, offset: -3)
        stroke.constrainRight(to: priceLabel, offset: 3)
    }
    
    private lazy var stroke: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = .textDiscount
        view.constrainHeight(to: 1.5)
        
        return view
    }()
    
    lazy var priceLabel = addPriceLabel()
    
    // MARK: - Discount Price Label
    
    private func constrainDiscountPriceLabel()
    {
        discountPriceLabel.constrainLeftToParent()
        discountPriceLabel.constrainRightToParent()
        discountPriceLabel.constrain(below: priceLabel)
    }
    
    lazy var discountPriceLabel = addPriceLabel(color: .textDiscount)
    
    private func addPriceLabel(color: Color = .text) -> Label
    {
        let label = addForAutoLayout(Label())
        
        label.font = Font.purchasePanel.nsFont
        label.alignment = .center
        label.textColor = color.nsColor
        
        return label
    }
}

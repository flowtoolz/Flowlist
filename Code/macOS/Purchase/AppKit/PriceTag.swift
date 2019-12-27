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
        
        observe(purchaseController).select(.didLoadFullVersionProduct)
        {
            [weak self] in self?.update()
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Present Data
    
    func update()
    {
        guard let price = fullVersionPrice,
            let priceLocale = fullVersionPriceLocale else { return }
        
        let appStorePrice = fullVersionFormattedPrice ?? ""
        discountPriceLabel.stringValue = "Introductory Price " + appStorePrice
        
        let discountAvailable = purchaseController.summerDiscountIsAvailable
        
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
        priceLabel.constrainToParentCenter(yOffset: -10)
        
        stroke.constrain(to: priceLabel.centerY.offset(1))
        stroke.constrain(to: priceLabel.left.offset(-3))
        stroke.constrain(to: priceLabel.right.offset(3))
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
        discountPriceLabel.constrainToParentLeft()
        discountPriceLabel.constrainToParentRight()
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
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

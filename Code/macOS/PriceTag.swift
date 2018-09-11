import AppKit
import StoreKit
import UIToolz
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
        guard let product = product else { return }
        
        let appStorePrice = product.formattedPrice ?? ""
        discountPriceLabel.stringValue = "Introductory Price " + appStorePrice
        
        let discountAvailable = fullVersionPurchaseController.summerDiscountIsAvailable
        
        if discountAvailable
        {
            var roundedPrice = product.price.intValue
            
            if Double(roundedPrice) < product.price.doubleValue
            {
                roundedPrice += 1
            }
            
            let roundedPriceNumber = NSDecimalNumber(value: roundedPrice)
            let regularPriceNumber = product.price.adding(roundedPriceNumber)
            
            let locale = product.priceLocale
            
            let regularPrice = regularPriceNumber.formattedPrice(in: locale) ?? ""
            
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
        priceLabel.constrainCenterY(to: self, offset: -10)
        priceLabel.constrainCenterX(to: self)
        
        stroke.constrainCenterY(to: priceLabel, offset: 1)
        stroke.constrainLeft(to: priceLabel, offset: -3)
        stroke.constrainRight(to: priceLabel, offset: 3)
    }
    
    private lazy var stroke: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = .discountRed
        view.constrainHeight(to: 1.5)
        
        return view
    }()
    
    lazy var priceLabel: Label = addPriceLabel()
    
    // MARK: - Discount Price Label
    
    private func constrainDiscountPriceLabel()
    {
        discountPriceLabel.constrainLeft(to: self)
        discountPriceLabel.constrainRight(to: self)
        discountPriceLabel.constrain(below: priceLabel)
    }
    
    lazy var discountPriceLabel: Label = addPriceLabel(color: .discountRed)
    
    private func addPriceLabel(color: Color = .black) -> Label
    {
        let label = addForAutoLayout(Label())
        
        label.font = Font.purchasePanel.nsFont
        label.alignment = .center
        label.textColor = color.nsColor
        
        return label
    }
    
    // MARK: - Product Information
    
    private var product: SKProduct?
    {
        return fullVersionPurchaseController.fullVersionProduct
    }
}

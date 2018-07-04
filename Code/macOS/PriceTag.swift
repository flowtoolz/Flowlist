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
        
        autoSetDimension(.height, toSize: 60, relation: .lessThanOrEqual)
        
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
        priceLabel.autoConstrainAttribute(.baseline, to: .horizontal, of: self)
        priceLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        
        stroke.autoConstrainAttribute(.horizontal,
                                      to: .horizontal,
                                      of: priceLabel,
                                      withOffset: 1)
        stroke.autoPinEdge(.left, to: .left, of: priceLabel, withOffset: -3)
        stroke.autoPinEdge(.right, to: .right, of: priceLabel, withOffset: 3)
    }
    
    private lazy var stroke: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = .discountRed
        view.autoSetDimension(.height, toSize: 1.5)
        
        return view
    }()
    
    lazy var priceLabel: Label = addPriceLabel()
    
    // MARK: - Discount Price Label
    
    private func constrainDiscountPriceLabel()
    {
        discountPriceLabel.autoPinEdge(toSuperviewEdge: .left)
        discountPriceLabel.autoPinEdge(toSuperviewEdge: .right)
        
        discountPriceLabel.autoPinEdge(.top, to: .bottom, of: priceLabel)
    }
    
    lazy var discountPriceLabel: Label = addPriceLabel(color: .discountRed)
    
    private func addPriceLabel(color: Color = .black) -> Label
    {
        let label = addForAutoLayout(Label())
        
        label.font = Font.text.nsFont
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

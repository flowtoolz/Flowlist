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
        priceLabel.stringValue = "regular price" //product?.formattedPrice ?? ""
        discountPriceLabel.stringValue = "discount price" //product?.formattedDiscountPrice ?? ""
        
        stroke.isHidden = !discountIsAvailable
        discountPriceLabel.isHidden = !discountIsAvailable
    }
    
    // MARK: - Price Label
    
    private func constrainPriceLabel()
    {
        priceLabel.autoPinEdge(toSuperviewEdge: .top)
        priceLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        
        stroke.autoConstrainAttribute(.horizontal,
                                      to: .top,
                                      of: priceLabel,
                                      withOffset: 18)
        stroke.autoPinEdge(.left, to: .left, of: priceLabel, withOffset: -10)
        stroke.autoPinEdge(.right, to: .right, of: priceLabel, withOffset: 10)
    }
    
    private lazy var stroke: LayerBackedView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = discountRed
        view.autoSetDimension(.height, toSize: 3)
        
        return view
    }()
    
    lazy var priceLabel: Label = addPriceLabel()
    
    // MARK: - Discount Price Label
    
    private func constrainDiscountPriceLabel()
    {
        discountPriceLabel.autoPinEdge(toSuperviewEdge: .bottom)
        discountPriceLabel.autoAlignAxis(toSuperviewAxis: .vertical)
        
        discountPriceLabel.autoPinEdge(.top, to: .bottom, of: priceLabel)
    }
    
    lazy var discountPriceLabel: Label = addPriceLabel(color: discountRed)
    
    private func addPriceLabel(color: Color = .black) -> Label
    {
        let label = addForAutoLayout(Label())
        
        label.font = Font.textLarge.nsFont
        label.alignment = .center
        label.textColor = color.nsColor
        
        return label
    }
    
    private let discountRed = Color(1.0, 0, 0, 0.5)
    
    // MARK: - Product Information
    
    private var discountIsAvailable: Bool
    {
        return true
        guard #available(OSX 10.13.2, *) else { return false }
        
        return product?.introductoryPrice != nil
    }
    
    private var product: SKProduct?
    {
        return fullVersionPurchaseController.fullVersionProduct
    }
}
import AppKit.NSView
import UIToolz
import SwiftObserver
import SwiftyToolz

class PurchaseContentView: NSView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainColumns()
        
        constrainOverview()
        
        constrainIcon()
        constrainPriceTag()
        constrainC2aButton()
        
        constrainDescriptionLabel()
        constrainLoadingIndicator()
        constrainErrorView()
        
        updateDescriptionLabel()
        
        observe(fullVersionPurchaseController)
        {
            [weak self] event in self?.didReceive(event)
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Load Data From AppStore
    
    private func didReceive(_ event: FullVersionPurchaseController.Event)
    {
        switch event
        {
            
        case .didNothing: break
        
        case .didFailToLoadFullVersionProduct:
            show(error: productLoadingFailedMessage)
            
        case .didLoadFullVersionProduct:
            updateDescriptionLabel()
            showDescription()
            c2aButton.isHidden = false
        
        case .didFailToPurchaseFullVersion(let message):
            log(error: message)
            show(error: purchaseFailedMessage)
            
        case .didPurchaseFullVersion:
            showDescription()
            isFullVersion = true
        }
    }
    
    // MARK: - Adjust to Loading State
    
    func reloadProductInfos()
    {
        showLoadingIndicator()
        c2aButton.isHidden = true
        fullVersionPurchaseController.loadFullVersionProductFromAppStore()
    }
    
    func showDescription()
    {
        descriptionLabel.isHidden = false
        loadingIndicator.isHidden = true
        errorView.isHidden = true
    }
    
    func showLoadingIndicator()
    {
        descriptionLabel.isHidden = true
        loadingIndicator.isHidden = false
        errorView.isHidden = true
    }
    
    private func show(error: String)
    {
        errorLabel.stringValue = error
        
        descriptionLabel.isHidden = true
        loadingIndicator.isHidden = true
        errorView.isHidden = false
    }
    
    // MARK: - Error View
    
    private func constrainErrorView()
    {
        errorView.autoPinEdge(toSuperviewEdge: .left)
        errorView.autoPinEdge(toSuperviewEdge: .right)
        errorView.autoPinEdge(toSuperviewEdge: .top)
        
        let insets = NSEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        errorLabel.autoPinEdgesToSuperviewEdges(with: insets)
    }
    
    private lazy var errorLabel: Label =
    {
        let label = errorView.addForAutoLayout(Label())
        
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        label.font = Font.text.nsFont
        
        return label
    }()
    
    private let productLoadingFailedMessage = "Could not reach AppStore.\n\nPlease make sure you have internet access. Then reopen this panel."
    
    private let purchaseFailedMessage = "Something went wrong.\n\nPlease make sure you have internet access and are eligible to pay for AppStore products. Then reopen this panel."
    
    private lazy var errorView: LayerBackedView =
    {
        let view = columns[2].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color(1.0, 0, 0, 0.5)
        view.isHidden = true
        view.layer?.cornerRadius = CGFloat(Float.cornerRadius)
        
        return view
    }()
    
    // MARK: - Loading Indicator
    
    private func constrainLoadingIndicator()
    {
        loadingIndicator.autoPinEdgesToSuperviewEdges()
        let insets = NSEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
        loadingLabel.autoPinEdgesToSuperviewEdges(with: insets,
                                                  excludingEdge: .bottom)
        spinner.autoCenterInSuperview()
    }
    
    private lazy var loadingLabel: Label =
    {
        let label = loadingIndicator.addForAutoLayout(Label())
        
        label.stringValue = "Loading infos from AppStore ..."
        label.font = Font.text.nsFont
        label.textColor = .white
        
        return label
    }()
    
    private lazy var spinner: NSProgressIndicator =
    {
        let view = loadingIndicator.addForAutoLayout(NSProgressIndicator())
        
        view.style = .spinning
        view.startAnimation(self)
        
        return view
    }()
    
    private lazy var loadingIndicator: LayerBackedView =
    {
        let view = columns[2].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color.flowlistBlue.with(alpha: 0.5)
        view.layer?.cornerRadius = CGFloat(Float.cornerRadius)
        
        return view
    }()
    
    // MARK: - Overview
    
    private func constrainOverview()
    {
        overview.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                              excludingEdge: .bottom)
    }
    
    private lazy var overview: PurchaseOverview = columns[0].addForAutoLayout(PurchaseOverview())
    
    // MARK: - App Icon
    
    private func constrainIcon()
    {
        icon.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                          excludingEdge: .bottom)
        icon.autoPinEdge(.bottom, to: .top, of: priceTag)
    }
    
    private lazy var icon: NSImageView =
    {
        let image = NSImage(named: NSImage.Name("AppIcon"))
        let imageView = NSImageView(withAspectFillImage: image)
        
        return columns[1].addForAutoLayout(imageView)
    }()
    
    // MARK: - Price Tag
    
    private func constrainPriceTag()
    {
        priceTag.autoPinEdge(.bottom,
                             to: .top,
                             of: c2aButtonBackground,
                             withOffset: -10)
        priceTag.autoPinEdge(toSuperviewEdge: .left)
        priceTag.autoPinEdge(toSuperviewEdge: .right)
    }
    
    private lazy var priceTag: PriceTag = columns[1].addForAutoLayout(PriceTag())
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButtonBackground.autoSetDimension(.height,
                                             toSize: CGFloat(Float.itemHeight))
        c2aButtonBackground.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                         excludingEdge: .top)
        
        c2aButtonLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
        c2aButtonLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        c2aButtonLabel.autoAlignAxis(.horizontal,
                                     toSameAxisOf: c2aButtonBackground)
        
        c2aButton.autoPinEdgesToSuperviewEdges()
    }
    
    private lazy var c2aButton: NSButton =
    {
        let button = c2aButtonBackground.addForAutoLayout(NSButton())
        
        button.title = ""
        button.font = Font.text.nsFont
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.target = self
        button.action = #selector(didClickC2aButton)
        
        return button
    }()
    
    @objc private func didClickC2aButton()
    {
        fullVersionPurchaseController.purchaseFullVersion()
    }
    
    private lazy var c2aButtonLabel: Label =
    {
        let label = c2aButtonBackground.addForAutoLayout(Label())
        
        label.stringValue = "Purchase or Restore Full Version"
        label.alignment = .center
        label.textColor = .white
        label.font = Font.text.nsFont
        
        return label
    }()
    
    private lazy var c2aButtonBackground: NSView =
    {
        let view = columns[1].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color.flowlistBlue
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        view.isHidden = true
        
        return view
    }()
    
    // MARK: - Description
    
    private func updateDescriptionLabel()
    {
        let product = fullVersionPurchaseController.fullVersionProduct
        let productDescription = product?.localizedDescription
        
        descriptionLabel.stringValue = productDescription ?? ""
    }
    
    private func constrainDescriptionLabel()
    {
        descriptionLabel.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                      excludingEdge: .bottom)
    }
    
    private lazy var descriptionLabel: Label =
    {
        let label = columns[2].addForAutoLayout(Label())
        
        label.lineBreakMode = .byWordWrapping
        label.font = Font.text.nsFont
        label.isHidden = true
        
        return label
    }()
    
    // MARK: - Columns
    
    private func constrainColumns()
    {
        for column in columns
        {
            column.autoPinEdge(toSuperviewEdge: .top)
            column.autoPinEdge(toSuperviewEdge: .bottom)
        }
        
        let gap = CGFloat(Float.itemHeight)
        
        columns[0].autoPinEdge(toSuperviewEdge: .left)
        
        columns[1].autoPinEdge(.left,
                               to: .right,
                               of: columns[0],
                               withOffset: gap)
        columns[1].autoMatch(.width, to: .width, of: columns[0])
        
        columns[2].autoPinEdge(.left,
                               to: .right,
                               of: columns[1],
                               withOffset: gap)
        columns[2].autoMatch(.width, to: .width, of: columns[1])
        columns[2].autoPinEdge(toSuperviewEdge: .right)
    }
    
    private lazy var columns: [NSView] = [addForAutoLayout(NSView()),
                                          addForAutoLayout(NSView()),
                                          addForAutoLayout(NSView())]
}

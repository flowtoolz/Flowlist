import AppKit.NSView
import UIToolz
import FoundationToolz
import SwiftObserver
import SwiftyToolz

class PurchaseContentView: NSView, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainColumns()
        
        constrainTitleLabel()
        constrainDescriptionLabel()
        
        constrainIcon()
        constrainPriceTag()
        constrainC2aButton()
        constrainLoadingIndicator()
        constrainErrorView()
        
        constrainBulletpointList()
        
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
            showPriceAndC2aButton()
        
        case .didFailToPurchaseFullVersion(let message):
            log(error: message)
            
        case .didPurchaseFullVersion:
            showPriceAndC2aButton()
            isFullVersion = true
        }
    }
    
    // MARK: - Adjust to Loading State
    
    func reloadProductInfos()
    {
        showLoadingIndicator()
        c2aButtonBackground.isHidden = true
        priceTag.isHidden = true
        fullVersionPurchaseController.loadFullVersionProductFromAppStore()
    }
    
    func showPriceAndC2aButton()
    {
        priceTag.isHidden = false
        c2aButtonBackground.isHidden = false
        loadingIndicator.isHidden = true
        errorView.isHidden = true
    }
    
    func showLoadingIndicator()
    {
        priceTag.isHidden = true
        c2aButtonBackground.isHidden = true
        loadingIndicator.isHidden = false
        errorView.isHidden = true
    }
    
    private func show(error: String)
    {
        errorLabel.stringValue = error
        
        priceTag.isHidden = true
        c2aButtonBackground.isHidden = true
        loadingIndicator.isHidden = true
        errorView.isHidden = false
    }
    
    // MARK: - Error View
    
    private func constrainErrorView()
    {
        errorView.autoPinEdge(toSuperviewEdge: .left)
        errorView.autoPinEdge(toSuperviewEdge: .right)
        errorView.autoPinEdge(toSuperviewEdge: .bottom)
        errorView.autoPinEdge(.top, to: .bottom, of: icon, withOffset: 10)
        
        let insets = NSEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
        errorLabel.autoPinEdgesToSuperviewEdges(with: insets,
                                                excludingEdge: .bottom)
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
    
    private lazy var errorView: LayerBackedView =
    {
        let view = columns[1].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color(1.0, 0, 0, 0.5)
        view.isHidden = true
        view.layer?.cornerRadius = CGFloat(Float.cornerRadius)
        
        return view
    }()
    
    // MARK: - Loading Indicator
    
    private func constrainLoadingIndicator()
    {
        loadingIndicator.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                      excludingEdge: .top)
        loadingIndicator.autoPinEdge(.top,
                                     to: .bottom,
                                     of: icon,
                                     withOffset: 10)
        let insets = NSEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
        loadingLabel.autoPinEdgesToSuperviewEdges(with: insets,
                                                  excludingEdge: .bottom)
        spinner.autoAlignAxis(toSuperviewAxis: .vertical)
        spinner.autoPinEdge(toSuperviewEdge: .bottom, withInset: 20)
    }
    
    private lazy var loadingLabel: Label =
    {
        let label = loadingIndicator.addForAutoLayout(Label())
        
        label.stringValue = "Loading infos from AppStore ..."
        label.font = Font.text.nsFont
        label.alignment = .center
        
        return label
    }()
    
    private lazy var spinner: NSProgressIndicator =
    {
        let view = loadingIndicator.addForAutoLayout(NSProgressIndicator())
        
        view.style = .spinning
        view.startAnimation(self)
        
        return view
    }()
    
    private lazy var loadingIndicator: NSView = columns[1].addForAutoLayout(NSView())
    
    // MARK: - Title Label
    
    private func constrainTitleLabel()
    {
        titleLabel.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                excludingEdge: .bottom)
    }
    
    private lazy var titleLabel: Label =
    {
        let label = columns[0].addForAutoLayout(Label())

        // TODO: specify weight in model class Font
        if #available(OSX 10.11.0, *)
        {
            label.font = NSFont.systemFont(ofSize: 26, weight: .bold)
        }
        else
        {
            label.font = NSFont.systemFont(ofSize: 26)
        }
        
        label.stringValue = "Flowlist Full Version"
        
        return label
    }()
    
    // MARK: - Bulletpoint List
    
    private func constrainBulletpointList()
    {
        bulletpointList.autoPinEdge(toSuperviewEdge: .left)
        bulletpointList.autoPinEdge(toSuperviewEdge: .right)
        bulletpointList.autoPinEdge(toSuperviewEdge: .top, withInset: 11)
    }
    
    private lazy var bulletpointList: BulletpointList = columns[2].addForAutoLayout(BulletpointList())
    
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
    
        c2aButtonBackground.autoPinEdge(toSuperviewEdge: .bottom)
        c2aButtonBackground.autoAlignAxis(toSuperviewAxis: .vertical)
        c2aButtonBackground.autoSetDimension(.width, toSize: 214)
        
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
        
        label.stringValue = "Purchase the Full Version"
        label.alignment = .center
        label.textColor = .white
        label.font = Font.text.nsFont
        
        return label
    }()
    
    private lazy var c2aButtonBackground: NSView =
    {
        let view = columns[1].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = .flowlistBlue
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        view.isHidden = true
        
        return view
    }()
    
    // MARK: - Description
    
    private func constrainDescriptionLabel()
    {
        descriptionLabel.autoPinEdge(toSuperviewEdge: .left)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .right)
        descriptionLabel.autoPinEdge(.top, to: .bottom, of: titleLabel, withOffset: 10)
    }
    
    private lazy var descriptionLabel: Label =
    {
        let label = columns[0].addForAutoLayout(Label())
        
        label.lineBreakMode = .byWordWrapping
        label.font = Font.text.nsFont
        label.stringValue = productDescription
        
        return label
    }()
    
    private let productDescription = """
        Flowlist is an elegant app for capturing ideas and managing tasks. Its editable item hierarchy makes it simple yet powerful. Be in a flow state while organizing your thoughts and your life!
        
        I have many features planned: A system wide shortcut for adding items, a synced iOS app, filters for search terms / colored tags / due dates, extensions that will make Flowlist a creative writing tool, and more.
        """
    
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

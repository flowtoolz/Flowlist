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
        constrainRestoreButton()
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
        
        case .didCancelLoadingFullversionProductBecauseOffline:
            show(error: productLoadingCanceledOfflineMessage)
            
        case .didFailToLoadFullVersionProduct:
            show(error: productLoadingFailedMessage)
            
        case .didLoadFullVersionProduct:
            showPriceAndC2aButton()
        
        case .didFailToPurchaseFullVersion(let message):
            log(error: message)
            
        case .didPurchaseFullVersion:
            showPriceAndC2aButton()
        }
    }
    
    // MARK: - Adjust to Loading State
    
    func reloadProductInfos()
    {
        showLoadingIndicator()
        c2aButton.isHidden = true
        priceTag.isHidden = true
        fullVersionPurchaseController.loadFullVersionProductFromAppStore()
    }
    
    func showPriceAndC2aButton()
    {
        priceTag.isHidden = false
        c2aButton.isHidden = false
        loadingIndicator.isHidden = true
        errorView.isHidden = true
    }
    
    func showLoadingIndicator()
    {
        priceTag.isHidden = true
        c2aButton.isHidden = true
        loadingIndicator.isHidden = false
        errorView.isHidden = true
    }
    
    private func show(error: String)
    {
        errorLabel.stringValue = error
        
        priceTag.isHidden = true
        c2aButton.isHidden = true
        loadingIndicator.isHidden = true
        errorView.isHidden = false
    }
    
    // MARK: - Error View
    
    private func constrainErrorView()
    {
        errorView.autoPinEdge(toSuperviewEdge: .left)
        errorView.autoPinEdge(toSuperviewEdge: .right)
        errorView.autoPinEdge(toSuperviewEdge: .bottom)
        errorView.autoMatch(.height,
                            to: .height,
                            of: columns[1],
                            withMultiplier: 0.4)
        
        errorLabel.autoMatch(.height,
                             to: .height,
                             of: errorView,
                             withMultiplier: 0.9)
        errorLabel.autoMatch(.width,
                             to: .width,
                             of: errorView,
                             withMultiplier: 0.9)
        errorLabel.autoCenterInSuperview()
    }
    
    private lazy var errorLabel: Label =
    {
        let label = errorView.addForAutoLayout(Label())
        
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        label.font = Font.text.nsFont
        
        return label
    }()
    
    private let productLoadingCanceledOfflineMessage = "You seem to be offline.\n\nPlease make sure you have internet access. Then reopen this panel."
    
    private let productLoadingFailedMessage = "Could not load infos from AppStore.\n\nPlease ensure Flowlist is up to date and you can access the AppStore. Then reopen this panel."
    
    private lazy var errorView: LayerBackedView =
    {
        let view = columns[1].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color.discountRed
        view.isHidden = true
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        
        return view
    }()
    
    // MARK: - Loading Indicator
    
    private func constrainLoadingIndicator()
    {
        loadingIndicator.autoPinEdge(toSuperviewEdge: .left)
        loadingIndicator.autoPinEdge(toSuperviewEdge: .right)
        loadingIndicator.autoPinEdge(.top,
                                     to: .bottom,
                                     of: icon,
                                     withOffset: 10)
        loadingIndicator.autoMatch(.height,
                                   to: .height,
                                   of: columns[1],
                                   withMultiplier: 0.4)
        let insets = NSEdgeInsets(top: 10, left: 10, bottom: 0, right: 10)
        loadingLabel.autoPinEdgesToSuperviewEdges(with: insets,
                                                  excludingEdge: .bottom)
        spinner.autoAlignAxis(toSuperviewAxis: .vertical)
        spinner.autoPinEdge(.top, to: .bottom, of: loadingLabel, withOffset: 20)
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

        label.font = Font.title.nsFont
        label.stringValue = "Flowlist Full Version"
        
        return label
    }()
    
    // MARK: - Bulletpoint List
    
    private func constrainBulletpointList()
    {
        bulletpointList.autoPinEdge(toSuperviewEdge: .left)
        bulletpointList.autoPinEdge(toSuperviewEdge: .right)
        bulletpointList.autoPinEdge(toSuperviewEdge: .top, withInset: 12)
    }
    
    private lazy var bulletpointList: BulletpointList = columns[2].addForAutoLayout(BulletpointList())
    
    // MARK: - App Icon
    
    private func constrainIcon()
    {
        icon.autoPinEdge(toSuperviewEdge: .top, withInset: 0)
        icon.autoPinEdge(toSuperviewEdge: .left)
        icon.autoPinEdge(toSuperviewEdge: .right)
        icon.autoMatch(.height,
                       to: .height,
                       of: columns[1],
                       withMultiplier: 0.35)
    }
    
    private lazy var icon: NSImageView =
    {
        let image = NSImage(named: .applicationIcon)
        let imageView = NSImageView(withAspectFillImage: image)
        
        return columns[1].addForAutoLayout(imageView)
    }()
    
    // MARK: - Price Tag
    
    private func constrainPriceTag()
    {
        priceTag.autoPinEdge(.top, to: .bottom, of: icon)
        priceTag.autoPinEdge(toSuperviewEdge: .left)
        priceTag.autoPinEdge(toSuperviewEdge: .right)
    }
    
    private lazy var priceTag: PriceTag = columns[1].addForAutoLayout(PriceTag())
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButton.autoSetDimension(.height, toSize: TaskView.heightWithSingleLine)
        c2aButton.autoPinEdge(.bottom,
                              to: .top,
                              of: restoreButton,
                              withOffset: -20)
        c2aButton.autoAlignAxis(toSuperviewAxis: .vertical)
        c2aButton.autoSetDimension(.width, toSize: 200)
    }
    
    private lazy var c2aButton: Button =
    {
        let button = columns[1].addForAutoLayout(Button())
        
        button.layer?.cornerRadius = Float.cornerRadius.cgFloat
        button.backgroundColor = Color(0.3, 0.6, 0.15)
        button.isHidden = true
        
        button.titleLabel.textColor = .white
        button.titleLabel.font = Font.text.nsFont
        
        button.title = "Purchase the Full Version"
        button.action =
        {
            [weak self] in
            
            self?.didClickC2aButton()
        }
        
        return button
    }()
    
    private func didClickC2aButton()
    {
        fullVersionPurchaseController.purchaseFullVersion()
    }
    
    // MARK: - Restore Button
    
    private func constrainRestoreButton()
    {
        restoreButton.autoSetDimension(.height,
                                       toSize: TaskView.heightWithSingleLine)
        restoreButton.autoPinEdge(toSuperviewEdge: .bottom)
        restoreButton.autoAlignAxis(toSuperviewAxis: .vertical)
        restoreButton.autoSetDimension(.width, toSize: 200)
    }
    
    private lazy var restoreButton: Button =
    {
        let button = columns[1].addForAutoLayout(Button())
        
        button.layer?.cornerRadius = Float.cornerRadius.cgFloat
        button.backgroundColor = Color.gray(brightness: 0.6)
        
        button.titleLabel.textColor = .white
        button.titleLabel.font = Font.text.nsFont
        
        button.title = "Restore Previous Purchase"
        button.action =
        {
            [weak self] in
            
            self?.didClickRestoreButton()
        }
        
        return button
    }()
    
    private func didClickRestoreButton()
    {
        fullVersionPurchaseController.restorePurchases()
    }
    
    // MARK: - Description
    
    private func constrainDescriptionLabel()
    {
        descriptionLabel.autoPinEdge(toSuperviewEdge: .left)
        descriptionLabel.autoPinEdge(toSuperviewEdge: .right)
        descriptionLabel.autoConstrainAttribute(.top,
                                                to: .bottom,
                                                of: titleLabel,
                                                withOffset: CGFloat(Font.defaultSize))
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
        Flowlist is an elegant self-management tool optimized for total creative focus. Hierarchical lists make it as simple and adaptable as a box of legos. Organize your thoughts and your life in a state of flow!
        
        I have many features planned, including:\nsynced iOS app, system wide shortcut for adding items, dark mode, filters for search terms / colored tags / due dates, exporting items as structured texts to txt, html, markdown and LaTeX ...
        """
    
    // MARK: - Columns
    
    private func constrainColumns()
    {
        for column in columns
        {
            column.autoPinEdge(toSuperviewEdge: .top)
            column.autoPinEdge(toSuperviewEdge: .bottom)
        }
        
        let gap = TaskView.heightWithSingleLine
        
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

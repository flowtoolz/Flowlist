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
    
    // MARK: - Dark Mode
    
    func adjustToColorMode()
    {
        
    }
    
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
        errorView.constrainToParentExcludingTop()
        errorView.constrainHeightToParent(with: 0.4)
        
        errorLabel.constrainSizeToParent(with: 0.9, 0.9)
        errorLabel.constrainCenterToParent()
    }
    
    private lazy var errorLabel: Label =
    {
        let label = errorView.addForAutoLayout(Label())
        
        label.lineBreakMode = .byWordWrapping
        label.textColor = .white
        label.font = Font.purchasePanel.nsFont
        
        return label
    }()
    
    private let productLoadingCanceledOfflineMessage = "You seem to be offline.\n\nPlease make sure you have internet access. Then reopen this panel."
    
    private let productLoadingFailedMessage = "Could not load infos from AppStore.\n\nPlease ensure Flowlist is up to date and you can access the AppStore. Then reopen this panel."
    
    private lazy var errorView: LayerBackedView =
    {
        let view = columns[1].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color.textDiscount
        view.isHidden = true
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        
        return view
    }()
    
    // MARK: - Loading Indicator
    
    private func constrainLoadingIndicator()
    {
        loadingIndicator.constrainLeftToParent()
        loadingIndicator.constrainRightToParent()
        loadingIndicator.constrain(below: icon, gap: 10)
        loadingIndicator.constrainHeightToParent(with: 0.4)

        loadingLabel.constrainToParentExcludingBottom(insetTop: 10,
                                                      insetLeft: 10,
                                                      insetRight: 10)
        
        spinner.constrainCenterXToParent()
        spinner.constrain(below: loadingLabel, gap: 20)
    }
    
    private lazy var loadingLabel: Label =
    {
        let label = loadingIndicator.addForAutoLayout(Label())
        
        label.textColor = Color.text.nsColor
        label.stringValue = "Loading infos from AppStore ..."
        label.font = Font.purchasePanel.nsFont
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
    
    private lazy var loadingIndicator = columns[1].addForAutoLayout(NSView())
    
    // MARK: - Title Label
    
    private func constrainTitleLabel()
    {
        titleLabel.constrainToParentExcludingBottom()
    }
    
    private lazy var titleLabel: Label =
    {
        let label = columns[0].addForAutoLayout(Label())

        label.textColor = Color.text.nsColor
        label.font = Font.title.nsFont
        label.stringValue = "Flowlist Full Version"
        
        return label
    }()
    
    // MARK: - Bulletpoint List
    
    private func constrainBulletpointList()
    {
        bulletpointList.constrainToParentExcludingBottom(insetTop: 12)
    }
    
    private lazy var bulletpointList = columns[2].addForAutoLayout(BulletpointList())
    
    // MARK: - App Icon
    
    private func constrainIcon()
    {
        icon.constrainToParentExcludingBottom()
        icon.constrainHeightToParent(with: 0.35)
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
        priceTag.constrain(below: icon)
        priceTag.constrainLeftToParent()
        priceTag.constrainRightToParent()
    }
    
    private lazy var priceTag = columns[1].addForAutoLayout(PriceTag())
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButton.constrainCenterXToParent()
        c2aButton.constrainSize(to: 200, 39)
        c2aButton.constrain(above: restoreButton, gap: 20)
    }
    
    private lazy var c2aButton: Button =
    {
        let button = columns[1].addForAutoLayout(Button())
        
        button.layer?.cornerRadius = Float.cornerRadius.cgFloat
        button.backgroundColor = Color(0.3, 0.6, 0.15)
        button.isHidden = true
        
        button.titleLabel.textColor = .white
        button.titleLabel.font = Font.purchasePanel.nsFont
        
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
        restoreButton.constrainCenterXToParent()
        restoreButton.constrainBottomToParent()
        restoreButton.constrainSize(to: 200, 39)
    }
    
    private lazy var restoreButton: Button =
    {
        let button = columns[1].addForAutoLayout(Button())
        
        button.layer?.cornerRadius = Float.cornerRadius.cgFloat
        button.backgroundColor = Color.gray(brightness: 0.6)
        
        button.titleLabel.textColor = .white
        button.titleLabel.font = Font.purchasePanel.nsFont
        
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
        descriptionLabel.constrainLeftToParent()
        descriptionLabel.constrainRightToParent()
        descriptionLabel.constrain(below: titleLabel, gap: 14)
    }
    
    private lazy var descriptionLabel: Label =
    {
        let label = columns[0].addForAutoLayout(Label())
        
        label.textColor = Color.text.nsColor
        label.lineBreakMode = .byWordWrapping
        label.font = Font.purchasePanel.nsFont
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
            column.constrainTopToParent()
            column.constrainBottomToParent()
        }
        
        let gap: CGFloat = 39
        
        columns[0].constrainLeftToParent()
        
        columns[1].constrain(toTheRightOf: columns[0], gap: gap)
        columns[1].constrainWidth(to: columns[0])
        
        columns[2].constrain(toTheRightOf: columns[1], gap: gap)
        columns[2].constrainWidth(to: columns[1])
        columns[2].constrainRightToParent()
    }
    
    private lazy var columns = [addForAutoLayout(NSView()),
                                addForAutoLayout(NSView()),
                                addForAutoLayout(NSView())]
}

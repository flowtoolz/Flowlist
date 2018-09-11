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
        guard let errorSuperView = errorView.superview else { return }
        
        errorView.constrainLeft(to: errorSuperView)
        errorView.constrainRight(to: errorSuperView)
        errorView.constrainBottom(to: errorSuperView)
        errorView.constrainHeight(to: 0.4, of: errorSuperView)
        
        errorLabel.constrainSize(to: 0.9, 0.9, of: errorView)
        errorLabel.constrainCenter(to: errorView)
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
        
        view.backgroundColor = Color.discountRed
        view.isHidden = true
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        
        return view
    }()
    
    // MARK: - Loading Indicator
    
    private func constrainLoadingIndicator()
    {
        guard let column = loadingIndicator.superview else { return }
        
        loadingIndicator.constrainLeft(to: column)
        loadingIndicator.constrainRight(to: column)
        loadingIndicator.constrain(below: icon, offset: 10)
        loadingIndicator.constrainHeight(to: 0.4, of: column)

        loadingLabel.constrainTop(to: loadingIndicator, offset: 10)
        loadingLabel.constrainLeft(to: loadingIndicator, offset: 10)
        loadingLabel.constrainRight(to: loadingIndicator, offset: -10)
        
        spinner.constrainCenterX(to: loadingIndicator)
        spinner.constrain(below: loadingLabel, offset: 20)
    }
    
    private lazy var loadingLabel: Label =
    {
        let label = loadingIndicator.addForAutoLayout(Label())
        
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
    
    private lazy var loadingIndicator: NSView = columns[1].addForAutoLayout(NSView())
    
    // MARK: - Title Label
    
    private func constrainTitleLabel()
    {
        guard let column = titleLabel.superview else { return }
        
        titleLabel.constrainTop(to: column)
        titleLabel.constrainLeft(to: column)
        titleLabel.constrainRight(to: column)
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
        guard let column = bulletpointList.superview else { return }
        
        bulletpointList.constrainLeft(to: column)
        bulletpointList.constrainRight(to: column)
        bulletpointList.constrainTop(to: column, offset: 12)
    }
    
    private lazy var bulletpointList: BulletpointList = columns[2].addForAutoLayout(BulletpointList())
    
    // MARK: - App Icon
    
    private func constrainIcon()
    {
        guard let column = icon.superview else { return }
        
        icon.constrainTop(to: column)
        icon.constrainLeft(to: column)
        icon.constrainRight(to: column)
        icon.constrainHeight(to: 0.35, of: column)
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
        guard let column = priceTag.superview else { return }
        
        priceTag.constrain(below: icon)
        priceTag.constrainLeft(to: column)
        priceTag.constrainRight(to: column)
    }
    
    private lazy var priceTag: PriceTag = columns[1].addForAutoLayout(PriceTag())
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        guard let column = c2aButton.superview else { return }
        
        c2aButton.constrainCenterX(to: column)
        c2aButton.constrainSize(to: 200, 39)
        c2aButton.constrain(above: restoreButton, offset: -20)
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
        guard let column = restoreButton.superview else { return }
        
        restoreButton.constrainCenterX(to: column)
        restoreButton.constrainBottom(to: column)
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
        guard let column = descriptionLabel.superview else { return }
        
        descriptionLabel.constrainLeft(to: column)
        descriptionLabel.constrainRight(to: column)
        descriptionLabel.constrain(below: titleLabel, offset: 14)
    }
    
    private lazy var descriptionLabel: Label =
    {
        let label = columns[0].addForAutoLayout(Label())
        
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
            column.constrainTop(to: self)
            column.constrainBottom(to: self)
        }
        
        let gap: CGFloat = 39
        
        columns[0].constrainLeft(to: self)
        
        columns[1].constrain(toTheRightOf: columns[0], offset: gap)
        columns[1].constrainWidth(to: columns[0])
        
        columns[2].constrain(toTheRightOf: columns[1], offset: gap)
        columns[2].constrainWidth(to: columns[1])
        columns[2].constrainRight(to: self)
    }
    
    private lazy var columns: [NSView] = [addForAutoLayout(NSView()),
                                          addForAutoLayout(NSView()),
                                          addForAutoLayout(NSView())]
}

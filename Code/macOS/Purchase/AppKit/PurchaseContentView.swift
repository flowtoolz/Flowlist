import AppKit.NSView
import UIToolz
import FoundationToolz
import SwiftObserver
import SwiftyToolz
import GetLaid

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
        
        observe(purchaseController)
        {
            [weak self] event in self?.didReceive(event)
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Dark Mode
    
    func adjustToColorMode()
    {
        let textColor = Color.text.nsColor
        titleLabel.textColor = textColor
        descriptionLabel.textColor = textColor
        priceTag.priceLabel.textColor = textColor
        priceTag.discountPriceLabel.textColor = Color.textDiscount.nsColor
        loadingLabel.textColor = textColor
        bulletpointList.adjustToColorMode()
        icon.image = Color.isInDarkMode ? iconImageDark : iconImageLight
        if #available(OSX 10.14, *)
        {
            spinner.appearance = NSAppearance(named: Color.isInDarkMode ? .darkAqua : .aqua)
        }
    }
    
    // MARK: - Load Data From AppStore
    
    private func didReceive(_ event: PurchaseController.Event)
    {
        switch event
        {
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
        purchaseController.loadFullVersionProductFromAppStore()
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
        errorView >> errorView.parent?.allButTop
        errorView.top >> errorView.parent?.bottom.at(0.6)
        
        errorLabel >> errorView.size.at(0.9)
        errorLabel >> errorView.center
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
        
        return view
    }()
    
    // MARK: - Loading Indicator
    
    private func constrainLoadingIndicator()
    {
        loadingIndicator >> loadingIndicator.parent?.left
        loadingIndicator >> loadingIndicator.parent?.right
        loadingIndicator.top >> icon.bottom.offset(10)
        loadingIndicator >> loadingIndicator.parent?.height.at(0.4)

        loadingLabel >> loadingIndicator.allButBottom(topOffset: 10,
                                                      leadingOffset: 10,
                                                      trailingOffset: -10)
        
        spinner >> loadingIndicator.centerX
        spinner.top >> loadingLabel.bottom.offset(20)
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
        
        if #available(OSX 10.14, *)
        {
            view.appearance = NSAppearance(named: Color.isInDarkMode ? .darkAqua : .aqua)
        }
        
        view.controlTint = .graphiteControlTint
        view.style = .spinning
        view.startAnimation(self)
        
        return view
    }()
    
    private lazy var loadingIndicator = columns[1].addForAutoLayout(NSView())
    
    // MARK: - Title Label
    
    private func constrainTitleLabel()
    {
        titleLabel >> allButBottom
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
        bulletpointList >> bulletpointList.parent?.allButBottom(topOffset: 12)
    }
    
    private lazy var bulletpointList = columns[2].addForAutoLayout(BulletpointList())
    
    // MARK: - App Icon
    
    private func constrainIcon()
    {
        icon >> icon.parent?.allButBottom
        icon >> icon.parent?.bottom.at(0.35)
    }
    
    private lazy var icon: NSImageView =
    {
        let image = Color.isInDarkMode ? iconImageDark : iconImageLight
        let imageView = NSImageView(withAspectFillImage: image)
        
        return columns[1].addForAutoLayout(imageView)
    }()
    
    private let iconImageLight = #imageLiteral(resourceName: "icon_pdf_black_border")
    private let iconImageDark = #imageLiteral(resourceName: "icon_pdf_white_border")
    
    // MARK: - Price Tag
    
    private func constrainPriceTag()
    {
        priceTag.top >> icon.bottom
        
        priceTag >> priceTag.parent?.left
        priceTag >> priceTag.parent?.right
    }
    
    private lazy var priceTag = columns[1].addForAutoLayout(PriceTag())
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButton >> c2aButton.parent?.centerX
        c2aButton >> (200, 39)
        c2aButton.bottom >> restoreButton.top.offset(-20)
    }
    
    private lazy var c2aButton: Button =
    {
        let button = columns[1].addForAutoLayout(Button())
        
        button.layer?.cornerRadius = Float.cornerRadius.cgFloat
        button.backgroundColor = Color(Int(95 * 0.8),
                                       Int(197 * 0.8),
                                       Int(64 * 0.8))
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
        purchaseController.purchaseFullVersion()
    }
    
    // MARK: - Restore Button
    
    private func constrainRestoreButton()
    {
        restoreButton >> restoreButton.parent?.centerX
        restoreButton >> restoreButton.parent?.bottom
        restoreButton >> (200, 39)
    }
    
    private lazy var restoreButton: Button =
    {
        let button = columns[1].addForAutoLayout(Button())
        
        button.layer?.cornerRadius = Float.cornerRadius.cgFloat
        button.backgroundColor = Color.gray(brightness: 0.3).with(alpha: 0.5)
        
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
        purchaseController.restorePurchases()
    }
    
    // MARK: - Description
    
    private func constrainDescriptionLabel()
    {
        descriptionLabel >> descriptionLabel.parent?.left
        descriptionLabel >> descriptionLabel.parent?.right
        descriptionLabel.top >> titleLabel.bottom.offset(14)
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
        Flowlist is an elegant self-management & writing tool optimized for total creative focus. Nested lists make it as simple and adaptable as a box of legos. Organize your thoughts and your life in a state of flow!
        
        I have many features planned:\nA synced iOS app, due dates with time filter & calendar view, drag'n'drop, references to files/images/folders, live keyword search and more.
        """
    
    // MARK: - Columns
    
    private func constrainColumns()
    {
        columns.forEach
        {
            $0 >> top
            $0 >> bottom
        }
        
        let gap: CGFloat = 39
        
        columns[0] >> left
        
        columns[1].left >> columns[0].right.offset(gap)
        columns[1] >> columns[0].width
        
        columns[2].left >> columns[1].right.offset(gap)
        columns[2] >> columns[1].width
        columns[2] >> right
    }
    
    private lazy var columns = [addForAutoLayout(NSView()),
                                addForAutoLayout(NSView()),
                                addForAutoLayout(NSView())]
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

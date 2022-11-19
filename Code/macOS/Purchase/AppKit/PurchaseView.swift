import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz
import GetLaid

class PurchaseView: LayerBackedView, SwiftObserver.ObservableObject, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        resetShadow()
        
        set(backgroundColor: .purchasePanelBackground)
        
        observe(Color.darkMode) { [weak self] _ in self?.adjustToColorMode() }
        
        constrainTopSeparator()
        constrainItemLabel()
        constrainProgressBar()
        constrainExpandIcon()
        constrainContent()
        constrainButtonOverlay()
        
        observe(TreeSelector.shared.numberOfUserCreatedLeafs).new()
        {
            [weak self] itemNumber in
            
            DispatchQueue.main.async { self?.update(itemNumber: itemNumber) }
        }
    }
    
    private func update(itemNumber: Int)
    {
        itemLabel.stringValue = labelText(for: itemNumber)
        itemLabel.textColor = labelColor(for: itemNumber).nsColor
        
        let progress = CGFloat(itemNumber) / CGFloat(maxNumberOfLeafsInTrial)
        progressBar.progress = progress
    }
    
    required init?(coder decoder: NSCoder) { nil }
    
    // MARK: - Dark Mode
    
    private func adjustToColorMode()
    {
        resetShadow()
        
        set(backgroundColor: .purchasePanelBackground)
        
        progressBar.set(backgroundColor: .progressBackground)
        progressBar.set(progressColor: .progressBar)
        progressBarSeparator.set(backgroundColor: .progressBarSeparator)
        
        let itemNumber = TreeSelector.shared.numberOfUserCreatedLeafs.value
        itemLabel.textColor = labelColor(for: itemNumber).nsColor
        
        expandIcon.image = isExpanded ? closeImage : expandImage
        
        content.adjustToColorMode()
    }
    
    // MARK: - Shadow
    
    private func resetShadow()
    {
        let color = Color.black
        let offset = CGSize(width: 0, height: 5)
        let opacity: Double = Color.isInDarkMode ? 0.5 : 0.05
        let radius: CGFloat = 5
        
        shadow = NSShadow()
        shadow?.shadowOffset = offset
        shadow?.shadowColor = color.with(alpha: opacity).nsColor
        shadow?.shadowBlurRadius = radius
        
        layer?.shadowColor = color.cgColor
        layer?.shadowOffset = offset
        layer?.shadowRadius = radius
        layer?.shadowOpacity = Float(opacity)
    }
    
    // MARK: - Expand / Collapse
    
    var isExpanded: Bool = false
    {
        didSet
        {
            if isExpanded { content.reloadProductInfos() }
            
            NSAnimationContext.beginGrouping()
            
            let context = NSAnimationContext.current
            context.allowsImplicitAnimation = true
            context.duration = 0.3
            
            content.alphaValue = isExpanded ? 1 : 0
            itemLabel.alphaValue = isExpanded ? 0 : 1
            expandIcon.image = isExpanded ? closeImage : expandImage
            progressBar.alphaValue = isExpanded ? 0 : 1
            
            NSAnimationContext.endGrouping()
        }
    }
    
    // MARK: - Top Separator
    
    private func constrainTopSeparator()
    {
        topSeparator >> allButBottom
        topSeparator.height >> 1
    }
    
    private lazy var topSeparator: LayerBackedView =
    {
        let separator = addForAutoLayout(LayerBackedView())
        separator.set(backgroundColor: .gray(brightness: 0.25).with(alpha: 0.17))
        return separator
    }()
    
    // MARK: - Item Label
    
    private func constrainItemLabel()
    {
        itemLabel >> left.offset(10)
        itemLabel.right >> expandIcon.left.offset(10)
        itemLabel >> buttonOverlay.centerY.offset(-CGFloat(Double.progressBarHeight / 2))
    }
    
    private lazy var itemLabel: Label =
    {
        let itemNumber = TreeSelector.shared.numberOfUserCreatedLeafs.value
        
        let field = addForAutoLayout(Label())
        field.font = Font.purchasePanel.nsFont
        let color = labelColor(for: itemNumber)
        field.textColor = color.nsColor
        field.stringValue = labelText(for: itemNumber)
        
        return field
    }()
    
    private func labelColor(for itemNumber: Int) -> Color
    {
        .itemText(isDone: itemNumber < 90,
                  isSelected: false,
                  isFocused: true)
    }
    
    private func labelText(for itemNumber: Int) -> String
    {
        "You have \(itemNumber) items. This trial version can hold up to \(maxNumberOfLeafsInTrial) items. Click here to learn about the unlimited full version."
    }
    
    // MARK: - Expand Icon
    
    private func constrainExpandIcon()
    {
        expandIcon >> right.offset(-14)
        expandIcon >> itemLabel.centerY
        expandIcon >> defaultIconSize
    }
    
    private let defaultIconSize: CGFloat = 17.0
    
    private lazy var expandIcon = addForAutoLayout(Icon(with: expandImage))
    
    private var closeImage: NSImage
    {
        Color.isInDarkMode ? closeImageWhite : closeImageBlack
    }
    
    private let closeImageBlack = #imageLiteral(resourceName: "close_indicator_pdf")
    private let closeImageWhite = #imageLiteral(resourceName: "close_indicator_white")
    
    private var expandImage: NSImage
    {
        Color.isInDarkMode ? expandImageWhite : expandImageBlack
    }
    
    private let expandImageBlack = #imageLiteral(resourceName: "expand_indicator_pdf")
    private let expandImageWhite = #imageLiteral(resourceName: "expand_indicator_white")
    
    // MARK: - Progress Bar
    
    private func constrainProgressBar()
    {
        progressBar >> allButTop
        progressBar.height >> Double.progressBarHeight
        
        progressBarSeparator >> progressBar.allButBottom
        progressBarSeparator.height >> 1
    }
    
    private lazy var progressBarSeparator: LayerBackedView =
    {
        let view = progressBar.addForAutoLayout(LayerBackedView())
        view.set(backgroundColor: .progressBarSeparator)
        
        return view
    }()
    
    private lazy var progressBar: ProgressBar =
    {
        let bar = ProgressBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bar, positioned: .below, relativeTo: buttonOverlay)
        
        let progress = CGFloat(TreeSelector.shared.numberOfUserCreatedLeafs.value) / CGFloat(maxNumberOfLeafsInTrial)
        bar.progress = progress
        bar.set(backgroundColor: .progressBackground)
        bar.set(progressColor: .progressBar)
        
        return bar
    }()
    
    // MARK: - Content
    
    private func constrainContent()
    {
        content.left >> right.at(0.05)
        content >> right.at(0.95)
        content.top >> bottom.at(0.1)
        content >> bottom.at(0.9)
    }
    
    private lazy var content: PurchaseContentView =
    {
        let view = PurchaseContentView()
        view.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(view, positioned: .below, relativeTo: buttonOverlay)
        
        view.alphaValue = 0
        
        return view
    }()
    
    // MARK: - Button Overlay
    
    private func constrainButtonOverlay()
    {
        buttonOverlay >> allButBottom
        buttonOverlay.height >> collapsedHeight
    }
    
    let collapsedHeight = 2 * Double.itemPadding(for: 17) + 17 + Double.progressBarHeight
    
    private lazy var buttonOverlay: NSButton =
    {
        let button = addForAutoLayout(NSButton())
        
        button.title = ""
        button.font = Font.purchasePanel.nsFont
        button.isBordered = false
        button.bezelStyle = .regularSquare
        button.target = self
        button.action = #selector(didClickExpandButton)
        
        return button
    }()
    
    @objc private func didClickExpandButton()
    {
        send(.expandButtonWasClicked)
    }
    
    // MARK: - Observable Observer
    
    let messenger = Messenger<Event>()
    enum Event { case expandButtonWasClicked }
    
    let receiver = Receiver()
}

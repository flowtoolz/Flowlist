import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class PurchaseView: LayerBackedView, CustomObservable, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        shadow = NSShadow()
        layer?.shadowColor = Color.black.cgColor
        layer?.shadowOffset = CGSize(width: 0, height: 5)
        layer?.shadowRadius = 5
        layer?.shadowOpacity = Color.isInDarkMode ? 0.5 : 0.05
        
        backgroundColor = .purchasePanelBackground
        
        observe(darkMode) { [weak self] _ in self?.adjustToColorMode() }
        
        constrainTopSeparator()
        constrainItemLabel()
        constrainProgressBar()
        constrainExpandIcon()
        constrainContent()
        constrainButtonOverlay()
        
        observe(numberOfUserCreatedLeafs)
        {
            [weak self] itemNumber in
            
            guard let self = self else { return }
            
            self.itemLabel.stringValue = self.labelText(for: itemNumber)
            self.itemLabel.textColor = self.labelColor(for: itemNumber).nsColor
            
            let progress = CGFloat(itemNumber) / CGFloat(maxNumberOfLeafsInTrial)
            self.progressBar.progress = progress
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopObserving() }
    
    // MARK: - Dark Mode
    
    private func adjustToColorMode()
    {
        backgroundColor = .purchasePanelBackground
        
        layer?.shadowOpacity = Color.isInDarkMode ? 0.5 : 0.05
        
        progressBar.backgroundColor = .progressBackground
        progressBar.progressColor = .progressBar
        progressBarSeparator.backgroundColor = .progressBarSeparator
        
        let itemNumber = numberOfUserCreatedLeafs.latestMessage
        itemLabel.textColor = labelColor(for: itemNumber).nsColor
        
        expandIcon.image = isExpanded ? closeImage : expandImage
        
        content.adjustToColorMode()
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
        topSeparator.constrainToParentExcludingBottom()
        topSeparator.constrainHeight(to: 1)
    }
    
    private lazy var topSeparator: LayerBackedView =
    {
        let edge = addForAutoLayout(LayerBackedView())
        
        edge.backgroundColor = Color.gray(brightness: 0.25).with(alpha: 0.17)
        
        return edge
    }()
    
    // MARK: - Item Label
    
    private func constrainItemLabel()
    {
        itemLabel.constrainLeftToParent(inset: 10)
        itemLabel.constrain(toTheLeftOf: expandIcon, gap: 10)
        itemLabel.constrainCenterY(to: buttonOverlay,
                                   offset: -CGFloat(Float.progressBarHeight / 2))
    }
    
    private lazy var itemLabel: Label =
    {
        let field = addForAutoLayout(Label())
        
        field.font = Font.purchasePanel.nsFont
        let color = labelColor(for: numberOfUserCreatedLeafs.latestMessage)
        field.textColor = color.nsColor
        
        let itemNumber = numberOfUserCreatedLeafs.latestMessage
        field.stringValue = labelText(for: itemNumber)
        
        return field
    }()
    
    private func labelColor(for itemNumber: Int) -> Color
    {
        return .itemText(isDone: itemNumber < 90,
                         isSelected: false,
                         isFocused: true)
    }
    
    private func labelText(for itemNumber: Int) -> String
    {
        return "You have \(itemNumber) items. This trial version can hold up to \(maxNumberOfLeafsInTrial) items. Click here to learn about the unlimited full version."
    }
    
    // MARK: - Expand Icon
    
    private func constrainExpandIcon()
    {
        expandIcon.constrainRightToParent(inset: 10)
        expandIcon.constrainCenterY(to: itemLabel)
        expandIcon.constrainSize(to: defaultIconSize, defaultIconSize)
    }
    
    private let defaultIconSize: CGFloat = 17.0
    
    private lazy var expandIcon = addForAutoLayout(Icon(with: expandImage))
    
    private var closeImage: NSImage
    {
        return Color.isInDarkMode ? closeImageWhite : closeImageBlack
    }
    
    private let closeImageBlack = #imageLiteral(resourceName: "close_indicator_pdf")
    private let closeImageWhite = #imageLiteral(resourceName: "close_indicator_white")
    
    private var expandImage: NSImage
    {
        return Color.isInDarkMode ? expandImageWhite : expandImageBlack
    }
    
    private let expandImageBlack = #imageLiteral(resourceName: "expand_indicator_pdf")
    private let expandImageWhite = #imageLiteral(resourceName: "expand_indicator_white")
    
    // MARK: - Progress Bar
    
    private func constrainProgressBar()
    {
        progressBar.constrainToParentExcludingTop()
        progressBar.constrainHeight(to: Float.progressBarHeight.cgFloat)
        
        progressBarSeparator.constrainToParentExcludingBottom()
        progressBarSeparator.constrainHeight(to: 1)
    }
    
    private lazy var progressBarSeparator: LayerBackedView =
    {
        let view = progressBar.addForAutoLayout(LayerBackedView())
        view.backgroundColor = .progressBarSeparator
        
        return view
    }()
    
    private lazy var progressBar: ProgressBar =
    {
        let bar = ProgressBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bar, positioned: .below, relativeTo: buttonOverlay)
        
        let progress = CGFloat(numberOfUserCreatedLeafs.latestMessage) / CGFloat(maxNumberOfLeafsInTrial)
        bar.progress = progress
        bar.backgroundColor = .progressBackground
        bar.progressColor = .progressBar
        
        return bar
    }()
    
    // MARK: - Content
    
    private func constrainContent()
    {
        content.constrainLeftToParent(at: 0.05)
        content.constrainRightToParent(at: 0.95)
        content.constrainTopToParent(at: 0.1)
        content.constrainBottomToParent(at: 0.9)
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
        buttonOverlay.constrainToParentExcludingBottom()
        buttonOverlay.constrainHeight(to: collapsedHeight)
    }
    
    let collapsedHeight = (2 * Float.itemPadding(for: 17) + 17 + Float.progressBarHeight).cgFloat
    
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
    
    // MARK: - Observability
    
    typealias Message = Event
    
    let messenger = Messenger(Event.didNothing)
    
    enum Event { case didNothing, expandButtonWasClicked }
}

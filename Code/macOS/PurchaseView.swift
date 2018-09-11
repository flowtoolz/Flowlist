import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class PurchaseView: LayerBackedView, Observable, Observer
{
    // MARK: - Life Cycle
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        backgroundColor = Color.gray(brightness: 0.92)
        layer?.borderColor = Color.border.cgColor
        layer?.borderWidth = 1.0
        
        constrainItemLabel()
        constrainProgressBar()
        constrainExpandIcon()
        constrainContent()
        constrainButtonOverlay()
        
        observe(numberOfUserCreatedTasks)
        {
            [weak self] itemNumber in
            
            guard let me = self else { return }
            
            me.itemLabel.stringValue = me.labelText(for: itemNumber)
            me.itemLabel.textColor = me.labelColor(for: itemNumber).nsColor
            
            let progress = CGFloat(itemNumber) / CGFloat(maxNumberOfTasksInTrial)
            me.progressBar.progress = progress
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
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
            expandIcon.image = isExpanded ? #imageLiteral(resourceName: "close_indicator_pdf") : #imageLiteral(resourceName: "expand_indicator_pdf")
            progressBar.alphaValue = isExpanded ? 0 : 1
            
            NSAnimationContext.endGrouping()
        }
    }
    
    // MARK: - Item Label
    
    private func constrainItemLabel()
    {
        itemLabel.constrainLeft(to: self, offset: 10)
        itemLabel.constrain(toTheLeftOf: expandIcon, offset: -10)
        itemLabel.constrainCenterY(to: buttonOverlay,
                                   offset: -CGFloat(Float.progressBarHeight / 2))
    }
    
    private lazy var itemLabel: Label =
    {
        let field = addForAutoLayout(Label())
        
        field.font = Font.purchasePanel.nsFont
        let color = labelColor(for: numberOfUserCreatedTasks.latestUpdate)
        field.textColor = color.nsColor
        
        let itemNumber = numberOfUserCreatedTasks.latestUpdate
        field.stringValue = labelText(for: itemNumber)
        
        return field
    }()
    
    private func labelColor(for itemNumber: Int) -> Color
    {
        return itemNumber >= 90 ? .black : .grayedOut
    }
    
    private func labelText(for itemNumber: Int) -> String
    {
        return "You have \(itemNumber) items. This trial version can hold up to \(maxNumberOfTasksInTrial) items. Click here to learn about the unlimited full version."
    }
    
    // MARK: - Expand Icon
    
    private func constrainExpandIcon()
    {
        expandIcon.constrainRight(to: self, offset: -10)
        expandIcon.constrainCenterY(to: itemLabel)
        expandIcon.constrainSize(to: defaultIconSize, defaultIconSize)
    }
    
    private let defaultIconSize: CGFloat = 17.0
    
    private lazy var expandIcon: Icon = addForAutoLayout(Icon(with: #imageLiteral(resourceName: "expand_indicator_pdf")))
    
    // MARK: - Progress Bar
    
    private func constrainProgressBar()
    {
        progressBar.constrainLeft(to: self)
        progressBar.constrainRight(to: self)
        progressBar.constrainBottom(to: self)
        progressBar.constrainHeight(to: Float.progressBarHeight.cgFloat)
    }
    
    private lazy var progressBar: ProgressBar =
    {
        let bar = ProgressBar()
        bar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(bar, positioned: .below, relativeTo: buttonOverlay)
        
        let progress = CGFloat(numberOfUserCreatedTasks.latestUpdate) / CGFloat(maxNumberOfTasksInTrial)
        bar.progress = progress
        bar.backgroundColor = .background
        bar.progressColor = .white
        bar.layer?.borderColor = Color.border.cgColor
        bar.layer?.borderWidth = 1.0
        
        return bar
    }()
    
    // MARK: - Content
    
    private func constrainContent()
    {
        content.constrainLeft(to: 0.05, of: self)
        content.constrainRight(to: 0.95, of: self)
        content.constrainTop(to: 0.1, of: self)
        content.constrainBottom(to: 0.9, of: self)
    }
    
    let collapsedHeight: CGFloat = 39 + Float.progressBarHeight.cgFloat
    
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
        buttonOverlay.constrainTop(to: self)
        buttonOverlay.constrainLeft(to: self)
        buttonOverlay.constrainRight(to: self)
        buttonOverlay.constrainHeight(to: 39 + Float.progressBarHeight.cgFloat)
    }
    
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
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, expandButtonWasClicked }
}

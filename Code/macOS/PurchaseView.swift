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
        
        backgroundColor = .white
        
        constrainItemLabel()
        constrainProgressBar()
        constrainExpandIcon()
        constrainExpandButton()
        
        constrainExpandedContent()
        constrainC2aButton()
        
        observe(numberOfUserCreatedTasks)
        {
            [weak self] newNumber in
            
            guard let me = self else { return }
            
            me.itemLabel.stringValue = me.composeItemText(with: newNumber)
            
            me.progressBar.progress = CGFloat(newNumber) / 100.0
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Expand / Collapse
    
    var isExpanded: Bool = false
    {
        didSet
        {
            NSAnimationContext.beginGrouping()
            
            let context = NSAnimationContext.current
            context.allowsImplicitAnimation = true
            context.duration = 0.3
            
            expandedContent.alphaValue = isExpanded ? 1 : 0
            itemLabel.alphaValue = isExpanded ? 0 : 1
            expandIcon.image = isExpanded ? #imageLiteral(resourceName: "close_indicator") : #imageLiteral(resourceName: "expand_indicator")
            
            NSAnimationContext.endGrouping()
        }
    }
    
    // MARK: - Item Label
    
    private func constrainItemLabel()
    {
        itemLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
        itemLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 20)
        itemLabel.autoAlignAxis(.horizontal,
                                toSameAxisOf: expandButton,
                                withOffset: -CGFloat(Float.progressBarHeight / 2))
    }
    
    private lazy var itemLabel: NSTextField =
    {
        let field = addForAutoLayout(NSTextField())
        
        field.drawsBackground = false
        field.isBezeled = false
        field.isEditable = false
        field.isBordered = false
        field.font = Font.text.nsFont
        field.textColor = Color.grayedOut.nsColor
        field.alignment = .center
        
        let itemNumber = numberOfUserCreatedTasks.latestUpdate
        field.stringValue = composeItemText(with: itemNumber)
        
        return field
    }()
    
    private func composeItemText(with number: Int) -> String
    {
        return "Items in use: \(number) of 100. Click to remove limit."
    }
    
    // MARK: - Expand Icon
    
    private func constrainExpandIcon()
    {
        expandIcon.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        expandIcon.autoAlignAxis(.horizontal, toSameAxisOf: itemLabel)
    }
    
    private lazy var expandIcon: NSImageView =
    {
        let icon = addForAutoLayout(NSImageView())
        
        icon.image = #imageLiteral(resourceName: "expand_indicator")
        icon.imageScaling = .scaleNone
        icon.imageAlignment = .alignCenter
        icon.alphaValue = 0.33
        
        return icon
    }()
    
    // MARK: - Expand Button
    
    private func constrainExpandButton()
    {
        expandButton.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                  excludingEdge: .bottom)
        
        let height = CGFloat(Float.itemHeight + Float.progressBarHeight)
        expandButton.autoSetDimension(.height, toSize: height)
    }
    
    private lazy var expandButton: NSButton =
    {
        let button = addForAutoLayout(NSButton())
        
        button.title = ""
        button.font = Font.text.nsFont
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
    
    // MARK: - Progress Bar
    
    private func constrainProgressBar()
    {
        progressBar.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                 excludingEdge: .top)
        
        let height = CGFloat(Float.progressBarHeight)
        progressBar.autoSetDimension(.height, toSize: height)
    }
    
    private lazy var progressBar: ProgressBar =
    {
        let bar = addForAutoLayout(ProgressBar())
        
        bar.progress = CGFloat(numberOfUserCreatedTasks.latestUpdate) / 100.0
        
        bar.backgroundColor = Color(0.6, 1.0, 0.5)
        bar.progressColor = Color(1.0, 0.6, 0.5)
        
        return bar
    }()
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButtonBackground.autoSetDimensions(to: CGSize(width: 200,
                                                         height: collapsedHeight))
        c2aButtonBackground.autoCenterInSuperview()
        c2aButton.autoPinEdgesToSuperviewEdges()
    }
    
    private lazy var c2aButton: NSButton =
    {
        let button = c2aButtonBackground.addForAutoLayout(NSButton())
        
        button.title = "Buy this shit now!"
        button.font = Font.text.nsFont
        button.isBordered = false
        button.bezelStyle = .regularSquare
        
        return button
    }()
    
    private lazy var c2aButtonBackground: NSView =
    {
        let view = expandedContent.addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color(0.9, 1.0, 0.8)
        
        return view
    }()
    
    let collapsedHeight = CGFloat(Float.itemHeight + Float.progressBarHeight)
    
    // MARK: - Expanded Content
    
    private func constrainExpandedContent()
    {
        expandedContent.autoPinEdge(toSuperviewEdge: .left)
        expandedContent.autoPinEdge(toSuperviewEdge: .right)
        expandedContent.autoPinEdge(.bottom, to: .top, of: progressBar)
        expandedContent.autoPinEdge(toSuperviewEdge: .top,
                                    withInset: CGFloat(Float.itemHeight))
    }
    
    private lazy var expandedContent: NSView =
    {
        let view = addForAutoLayout(NSView())
        
        view.alphaValue = 0
        
        return view
    }()
    
    // MARK: - Observability
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, expandButtonWasClicked }
}

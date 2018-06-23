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
        constrainExpandButton()
        
        constrainExpandedContent()
        constrainC2aButton()
        
        observe(numberOfUserCreatedTasks)
        {
            [weak self] newNumber in
            
            guard let me = self else { return }
            
            me.itemLabel.stringValue = me.composeItemText(with: newNumber)
        }
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButtonBackground.autoSetDimensions(to: CGSize(width: 200, height: 64))
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
    
    // MARK: - Item Label
    
    private func constrainItemLabel()
    {
        itemLabel.autoAlignAxis(.horizontal, toSameAxisOf: expandButton)
        itemLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 20)
    }
    
    private lazy var itemLabel: NSTextField =
    {
        let field = addForAutoLayout(NSTextField())
        
        field.drawsBackground = false
        field.isBezeled = false
        field.isEditable = false
        field.isBordered = false
        field.font = Font.text.nsFont
        
        let itemNumber = numberOfUserCreatedTasks.latestUpdate
        field.stringValue = composeItemText(with: itemNumber)
        
        return field
    }()
    
    private func composeItemText(with number: Int) -> String
    {
        return "Items: \(number)"
    }
    
    // MARK: - Expand Button
    
    private func constrainExpandButton()
    {
        expandButtonBackground.autoPinEdge(toSuperviewEdge: .top)
        expandButtonBackground.autoPinEdge(toSuperviewEdge: .right)
        expandButtonBackground.autoSetDimensions(to: CGSize(width: 100, height: 64))
        expandButton.autoPinEdgesToSuperviewEdges()
    }
    
    private lazy var expandButton: NSButton =
    {
        let button = expandButtonBackground.addForAutoLayout(NSButton())
        
        button.title = "Expand"
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
    
    private lazy var expandButtonBackground: NSView =
    {
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color(0.9, 1.0, 0.8)
        
        return view
    }()
    
    // MARK: - Expanded Content
    
    private func constrainExpandedContent()
    {
        expandedContent.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                     excludingEdge: .top)
        expandedContent.autoPinEdge(toSuperviewEdge: .top, withInset: 64)
    }
    
    var isExpanded: Bool = false
    {
        didSet
        {
            NSAnimationContext.beginGrouping()
            
            let context = NSAnimationContext.current
            context.allowsImplicitAnimation = true
            context.duration = 0.3
            
            expandedContent.alphaValue = isExpanded ? 1 : 0
            
            NSAnimationContext.endGrouping()
        }
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

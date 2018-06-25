import AppKit.NSView
import UIToolz
import SwiftyToolz

class PurchaseContentView: NSView
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainColumns()
        constrainC2aButton()
        constrainIcon()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - App Icon
    
    private func constrainIcon()
    {
        icon.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                          excludingEdge: .bottom)
        icon.autoPinEdge(.bottom, to: .top, of: c2aButton, withOffset: -10)
    }
    
    private lazy var icon: NSImageView =
    {
        let image = NSImage(named: NSImage.Name("AppIcon"))
        let imageView = NSImageView(withAspectFillImage: image)
        
        return columns[1].addForAutoLayout(imageView)
    }()
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButtonBackground.autoSetDimension(.height, toSize: CGFloat(Float.itemHeight))
        c2aButtonBackground.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                         excludingEdge: .top)
        
        c2aButtonLabel.autoPinEdge(toSuperviewEdge: .left, withInset: 10)
        c2aButtonLabel.autoPinEdge(toSuperviewEdge: .right, withInset: 10)
        c2aButtonLabel.autoAlignAxis(.horizontal, toSameAxisOf: c2aButtonBackground)
        
        c2aButton.autoPinEdgesToSuperviewEdges()
    }
    
    private lazy var c2aButton: NSButton =
    {
        let button = c2aButtonBackground.addForAutoLayout(NSButton())
        
        button.title = ""
        button.font = Font.text.nsFont
        button.isBordered = false
        button.bezelStyle = .regularSquare
        
        return button
    }()
    
    private lazy var c2aButtonLabel: Label =
    {
        let label = c2aButtonBackground.addForAutoLayout(Label())
        
        label.stringValue = "Unlock Full Version"
        label.alignment = .center
        label.textColor = .white
        label.font = Font.text.nsFont
        
        return label
    }()
    
    private lazy var c2aButtonBackground: NSView =
    {
        let view = columns[1].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color.flowlistBlue
        view.layer?.cornerRadius = Float.cornerRadius.cgFloat
        
        return view
    }()
    
    // MARK: - Columns
    
    private func constrainColumns()
    {
        for column in columns
        {
            column.autoPinEdge(toSuperviewEdge: .top)
            column.autoPinEdge(toSuperviewEdge: .bottom)
        }
        
        columns[0].autoPinEdge(toSuperviewEdge: .left)
        
        columns[1].autoPinEdge(.left, to: .right, of: columns[0], withOffset: 10)
        columns[1].autoMatch(.width, to: .width, of: columns[0])
        
        columns[2].autoPinEdge(.left, to: .right, of: columns[1], withOffset: 10)
        columns[2].autoMatch(.width, to: .width, of: columns[1])
        columns[2].autoPinEdge(toSuperviewEdge: .right)
    }
    
    private lazy var columns: [NSView] = [addForAutoLayout(NSView()),
                                          addForAutoLayout(NSView()),
                                          addForAutoLayout(NSView())]
}

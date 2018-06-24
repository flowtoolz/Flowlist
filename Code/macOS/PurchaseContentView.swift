import AppKit.NSView
import UIToolz
import SwiftyToolz

class PurchaseContentView: NSView
{
    // MARK: - Initialization
    
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        constrainC2aButton()
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButtonBackground.autoSetDimensions(to: CGSize(width: 200,
                                                         height: CGFloat(Float.itemHeight)))
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
        let view = addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color(0.9, 1.0, 0.8)
        
        return view
    }()
}

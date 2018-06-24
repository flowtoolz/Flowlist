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
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - C2A Button
    
    private func constrainC2aButton()
    {
        c2aButtonBackground.autoSetDimension(.height, toSize: CGFloat(Float.itemHeight))
        c2aButtonBackground.autoPinEdgesToSuperviewEdges(with: NSEdgeInsetsZero,
                                                         excludingEdge: .top)
        
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
        let view = columns[1].addForAutoLayout(LayerBackedView())
        
        view.backgroundColor = Color(0.9, 1.0, 0.8)
        
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
    
    private lazy var columns: [LayerBackedView] = [addForAutoLayout(LayerBackedView()),
                                          addForAutoLayout(LayerBackedView()),
                                          addForAutoLayout(LayerBackedView())]
}

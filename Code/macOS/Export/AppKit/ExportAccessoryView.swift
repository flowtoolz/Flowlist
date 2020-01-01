import AppKit
import UIToolz
import GetLaid

class ExportAcessoryView: NSView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        translatesAutoresizingMaskIntoConstraints = false
        constrain(to: .min(400, 40))
        
        formatContainer.constrainToParentTop()
        formatContainer.constrainToParentBottom()
        formatContainer.constrainToParentCenterX()
        
        formatLabel.constrainToParentLeft(inset: 10)
        formatLabel.constrainToParentCenterY()
        
        formatMenu.constrain(toTheRightOf: formatLabel, gap: 10)
        formatMenu.constrainToParentButLeft(inset: 10)
    }
    
    required init?(coder decoder: NSCoder) { fatalError() }
    
    private lazy var formatLabel: Label =
    {
        let label = formatContainer.addForAutoLayout(Label())
        
        label.font = .system
        label.stringValue = "Select Format:"
        label.alignment = .right
        
        return label
    }()
    
    var selectedFormat: TextFormat
    {
        TextFormat.allCases[formatMenu.indexOfSelectedItem]
    }
    
    lazy var formatMenu: NSPopUpButton =
    {
        let menu = formatContainer.addForAutoLayout(NSPopUpButton())
        
        menu.addItems(withTitles: TextFormat.allCases.map { $0.rawValue })
        menu.selectItem(withTitle: TextFormat.preferred.rawValue)
        
        return menu
    }()
    
    private lazy var formatContainer = addForAutoLayout(NSView())
}

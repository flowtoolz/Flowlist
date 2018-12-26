import AppKit
import UIToolz
import GetLaid

class ExportAcessoryView: NSView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        translatesAutoresizingMaskIntoConstraints = false
        constrainWidth(toMinimum: 400)
        constrainHeight(toMinimum: 40)
        
        formatContainer.constrainTopToParent()
        formatContainer.constrainBottomToParent()
        formatContainer.constrainCenterXToParent()
        
        formatLabel.constrainLeftToParent(inset: 10)
        formatLabel.constrainCenterYToParent()
        
        formatMenu.constrain(toTheRightOf: formatLabel, gap: 10)
        formatMenu.constrainToParentExcludingLeft(insetTop: 10,
                                                  insetBottom: 10,
                                                  insetRight: 10)
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
        return TextFormat.allCases[formatMenu.indexOfSelectedItem]
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

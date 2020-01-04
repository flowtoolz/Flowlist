import AppKit
import UIToolz
import GetLaid

class ExportAcessoryView: NSView
{
    override init(frame frameRect: NSRect)
    {
        super.init(frame: frameRect)
        
        translatesAutoresizingMaskIntoConstraints = false
        self >> .min(400, 40)
        
        formatContainer >> top
        formatContainer >> bottom
        formatContainer >> centerX
        
        formatLabel >> formatContainer.left.offset(10)
        formatLabel >> formatContainer.centerY
        
        formatMenu.left >> formatLabel.right.offset(10)
        formatMenu >> formatContainer.allButLeft(topOffset: 10,
                                                 bottomOffset: -10,
                                                 rightOffset: -10)
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

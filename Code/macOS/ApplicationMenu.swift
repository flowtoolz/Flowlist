import AppKit
import SwiftObserver
import SwiftyToolz

class ApplicationMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Application Menu")
        
        addItem(increaseFontSizeItem)
        addItem(decreaseFontSizeItem)
        addItem(darkModeItem)
        
        addItem(NSMenuItem.separator())
 
        addItem(withTitle: "Hide Flowlist",
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h")
        addItem(withTitle: "Quit Flowlist",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q")
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Changing Font Size
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        switch menuItem
        {
        case increaseFontSizeItem:
            return !TextView.isEditing
            
        case decreaseFontSizeItem:
            return !TextView.isEditing && Font.baseSize.latestUpdate > 12
            
        default: return true
        }
    }
    
    private lazy var increaseFontSizeItem = MenuItem("Bigger Font",
                                                     key: "+",
                                                     validator: self)
    { Font.baseSizeVar += 1 }
    
    private lazy var decreaseFontSizeItem = MenuItem("Smaller Font",
                                                     key: "-",
                                                     validator: self)
    { Font.baseSizeVar -= 1 }
    
    // MARK: - Dark Mode
    
    private lazy var darkModeItem = MenuItem("Toggle Dark Mode",
                                             key: "d",
                                             validator: self)
    { Color.isInDarkMode = !Color.isInDarkMode }
}

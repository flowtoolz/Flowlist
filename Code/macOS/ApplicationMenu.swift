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
    
    private lazy var increaseFontSizeItem = item("Bigger Font",
                                        action: #selector(makeFontBigger),
                                        key: "+")
    @objc private func makeFontBigger() { Font.baseSizeVar += 1 }
    
    private lazy var decreaseFontSizeItem = item("Smaller Font",
                                                 action: #selector(makeFontSmaller),
                                                 key: "-")
    @objc private func makeFontSmaller() { Font.baseSizeVar -= 1 }
}

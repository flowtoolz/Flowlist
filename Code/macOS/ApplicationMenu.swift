import AppKit
import SwiftObserver
import SwiftyToolz

class ApplicationMenu: NSMenu, Observer
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Application Menu")
        
        addItem(exportItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(increaseFontSizeItem)
        addItem(decreaseFontSizeItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(darkModeItem)
        
        addItem(NSMenuItem.separator())
 
        addItem(withTitle: "Hide Flowlist",
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h")
        addItem(withTitle: "Quit Flowlist",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q")
        
        observeDarkMode()
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Changing Font Size
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        let mainWindowIsKey = NSApp.mainWindow?.isKeyWindow ?? false
        
        switch menuItem
        {
        case increaseFontSizeItem:
            return !TextView.isEditing && mainWindowIsKey
            
        case decreaseFontSizeItem:
            return !TextView.isEditing && Font.baseSize.latestUpdate > 12 && mainWindowIsKey
            
        case darkModeItem, exportItem:
            return mainWindowIsKey
            
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
    
    private func observeDarkMode()
    {
        observe(darkMode)
        {
            [weak self] _ in
            
            guard let me = self else { return }
            
            me.darkModeItem.title = me.darkModeOptionTitle
        }
    }
    
    private lazy var darkModeItem = MenuItem(self.darkModeOptionTitle,
                                             key: "d",
                                             validator: self)
    {
        Color.isInDarkMode = !Color.isInDarkMode
    }
    
    private var darkModeOptionTitle: String
    {
        return "\(Color.isInDarkMode ? "Daylight" : "Dark") Mode"
    }
    
    // MARK: - Export
    
    private lazy var exportItem = MenuItem("Export List as Text",
                                           key: "e",
                                           validator: self)
    {
        browser.focusedList.root?.export()
    }
}

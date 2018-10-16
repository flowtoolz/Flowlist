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
 
        addItem(withTitle: "Hide Flowlist",
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h")
        addItem(withTitle: "Quit Flowlist",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q")
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        let mainWindowIsKey = NSApp.mainWindow?.isKeyWindow ?? false
        
        switch menuItem
        {
        case exportItem: return mainWindowIsKey
        default: return true
        }
    }
    
    // MARK: - Export
    
    private lazy var exportItem = MenuItem("Export List as Text",
                                           key: "e",
                                           validator: self)
    {
        browser.focusedList.root?.export()
    }
}

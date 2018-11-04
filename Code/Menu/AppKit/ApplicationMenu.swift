import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class ApplicationMenu: NSMenu, NSMenuItemValidation, Observer
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Application Menu")
        
        let exportItem = makeItem("Export List ...", key: "e", id: "export")
        {
            browser.focusedList.root?.export()
        }
        
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
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        let mainWindowIsKey = NSApp.mainWindow?.isKeyWindow ?? false
        
        switch menuItem.id
        {
        case "export": return mainWindowIsKey
        default: return true
        }
    }
}

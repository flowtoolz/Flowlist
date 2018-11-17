import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class DataMenu: NSMenu, NSMenuItemValidation
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Data")
        
        let exportItem = makeItem("Export List as Text...", key: "e", id: "export")
        {
            browser.focusedList.root?.export()
        }
        
        addItem(exportItem)
        
        let cloudItem = makeItem("Start Using iCloud", id: "iCloud")
        {
            // TODO: ...
        }
        
        addItem(cloudItem)
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

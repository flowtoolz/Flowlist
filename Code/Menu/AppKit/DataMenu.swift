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
        
        addItem(cloudItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        cloudItem.title = cloudItemTitle
        
        let mainWindowIsKey = NSApp.mainWindow?.isKeyWindow ?? false
        
        switch menuItem.id
        {
        case "export": return mainWindowIsKey
        default: return true
        }
    }
    
    private lazy var cloudItem = makeItem(cloudItemTitle)
    {
        Storage.shared.isUsingDatabase.toggle()
    }
    
    private var cloudItemTitle: String
    {
        let usesICloud = Storage.shared.isUsingDatabase
        return "\(usesICloud ? "Stop" : "Start") Using iCloud"
    }
}

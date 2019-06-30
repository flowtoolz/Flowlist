import AppKit
import UIToolz
import SwiftObserver

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
        
        addItem(NSMenuItem.separator())
        
        let finderItem = makeItem("Show JSON File in Finder")
        {
            let fileURL = StorageController.shared.persister.url
            
            NSWorkspace.shared.activateFileViewerSelecting([fileURL])
        }
        
        addItem(finderItem)
        
        addItem(cloudItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Item Validation and Titles
    
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
    
    // MARK: - iCloud Item
    
    private lazy var cloudItem = makeItem(cloudItemTitle)
    {
        StorageController.shared.storage.toggleIntentionToSyncWithDatabase()
    }
    
    private var cloudItemTitle: String
    {
        let isUsingICloud = StorageController.shared.storage.isIntendingToSync
        return "\(isUsingICloud ? "Stop" : "Start") Using iCloud"
    }
}

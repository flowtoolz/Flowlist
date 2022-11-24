import AppKit
import SwiftUIToolz
import SwiftObserver

class DataMenu: NSMenu, NSMenuItemValidation
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Data")
        
        addItem(exportItem)
        addItem(finderItem)
        
        if isCKSyncFeatureAvailable
        {
            addItem(NSMenuItem.separator())
            addItem(cloudItem)
        }
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Item Validation
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        cloudItem.title = cloudItemTitle
        
        let mainWindowIsKey = NSApp.mainWindow?.isKeyWindow ?? false
        
        switch menuItem.id
        {
        case exportItem.id: return mainWindowIsKey
        default: return true
        }
    }
    
    // Export Item
    
    private lazy var exportItem = makeItem("Export List as Text...",
                                           key: "e",
                                           id: "export")
    {
        browser.focusedList.root?.export()
    }
    
    // Finder Item
    
    private lazy var finderItem = makeItem("Show Item Files in Finder",
                                           id: "show folder")
    {
        NSWorkspace.shared.activateFileViewerSelecting([FileDatabase.shared.directory])
    }
    
    // MARK: - iCloud Item
    
    private lazy var cloudItem = makeItem(cloudItemTitle)
    {
        StorageController.shared.toggleIntentionToSyncWithDatabase()
    }
    
    private var cloudItemTitle: String
    {
        "\(CKSyncIntention.shared.isActive ? "Stop" : "Start") Using iCloud"
    }
}

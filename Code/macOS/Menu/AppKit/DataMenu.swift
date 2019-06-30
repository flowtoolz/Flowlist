import AppKit
import UIToolz
import SwiftObserver

class DataMenu: NSMenu, NSMenuItemValidation
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Data")
        
        addItem(exportItem)
        addItem(finderItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(cloudItem)
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
        case finderItem.id: return StorageController.shared.persister.directory != nil
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
    
    private lazy var finderItem = makeItem("Show Item File Folder in Finder",
                                           id: "show folder")
    {
        if let folder = StorageController.shared.persister.directory
        {
            NSWorkspace.shared.activateFileViewerSelecting([folder])
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

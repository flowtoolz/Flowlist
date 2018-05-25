import AppKit

class Menu: NSMenu
{
    // MARK: - Life Cycle
    
    init()
    {
        super.init(title: "Flowlist")
        
        addItem(applicationMenuItem())
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Appliaction Menu
    
    private func applicationMenuItem() -> NSMenuItem
    {
        let menuItem = NSMenuItem(title: appMenuTitle,
                                  action: nil,
                                  keyEquivalent: "")
        
        menuItem.submenu = applicationMenu()
        
        return menuItem
    }
    
    private func applicationMenu() -> NSMenu
    {
        let menu = NSMenu(title: appMenuTitle)
        
        menu.addItem(withTitle: "Hide",
                    action: #selector(NSApplication.hide(_:)),
                    keyEquivalent: "h")
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(focusItem)
        menu.addItem(fullscreenItem)
        
        menu.addItem(NSMenuItem.separator())
        
        menu.addItem(withTitle: "Quit",
                     action: #selector(NSApplication.terminate(_:)),
                     keyEquivalent: "q")
        
        return menu
    }
    
    private let appMenuTitle = "Application"
    
    // MARK: - Toggle Fullscreen
    
    func windowChangesFullscreen(to fullscreen: Bool)
    {
        focusItem.isEnabled = !fullscreen
        fullscreenItem.title = fullscreenItemTitle(isFullscreen: fullscreen)
    }
    
    @objc private func toggleFullscreen()
    {
        NSApp.mainWindow?.toggleFullScreen(self)
    }
    
    private lazy var fullscreenItem: NSMenuItem =
    {
        let item = NSMenuItem()
        item.target = self
        item.title = fullscreenItemTitle(isFullscreen: false)
        item.action = #selector(toggleFullscreen)
        item.keyEquivalent = "f"
        return item
    }()
    
    private func fullscreenItemTitle(isFullscreen: Bool) -> String
    {
        return isFullscreen ? "Leave Fullscreen" : "Fullscreen"
    }
    
    // MARK: - Toggle Focus
    
    @objc private func toggleFocus()
    {
        let options: NSApplication.PresentationOptions = [.autoHideMenuBar,
                                                          .autoHideDock]
        
        let gonnaFocus = !NSApp.currentSystemPresentationOptions.contains(options)
        
        fullscreenItem.isEnabled = !gonnaFocus
        focusItem.title = focusItemTitle(isFocused: gonnaFocus)
        
        if gonnaFocus
        {
            NSApp.presentationOptions.insert(options)
            NSApp.hideOtherApplications(self)
        }
        else
        {
            NSApp.unhideAllApplications(self)
            NSApp.presentationOptions.remove(options)
        }
    }
    
    private lazy var focusItem: NSMenuItem =
    {
        let item = NSMenuItem()
        item.target = self
        item.title = focusItemTitle(isFocused: false)
        item.action = #selector(toggleFocus)
        return item
    }()
    
    private func focusItemTitle(isFocused: Bool) -> String
    {
        return isFocused ? "Stop Focussing" : "Focus"
    }
    
    // MARK: - Custom Item Enabeling
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        return menuItem.isEnabled
    }
}

//menu.addItem(withTitle: "Select All",
//             action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
//menu.addItem(withTitle: "Copy",
//             action: #selector(NSText.copy(_:)), keyEquivalent: "c")

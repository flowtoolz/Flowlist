import AppKit

class Menu: NSMenu
{
    // MARK: - Life Cycle
    
    init()
    {
        super.init(title: "Flowlist")

        addItem(appMenuItem())
        addItem(fileMenuItem())
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Create Menu Items
    
    private func appMenuItem() -> NSMenuItem
    {
        let appMenu = NSMenu(title: "Application")
        appMenu.addItem(withTitle: "About Me", action: nil, keyEquivalent: "")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Preferences...", action: nil, keyEquivalent: ",")
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Hide Me", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem({ () -> NSMenuItem in
            let m = NSMenuItem(title: "Hide Others", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
            m.keyEquivalentModifierMask = [.command, .option]
            return m
            }())
        appMenu.addItem(withTitle: "Show All", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        
        appMenu.addItem(NSMenuItem.separator())
        let appServicesMenu = NSMenu()
        NSApp.servicesMenu = appServicesMenu
        appMenu.addItem(withTitle: "Services", action: nil, keyEquivalent: "").submenu = appServicesMenu
        appMenu.addItem(NSMenuItem.separator())
        appMenu.addItem(withTitle: "Quit Me", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        
        let appMenuItem = NSMenuItem(title: "Application",
                                     action: nil,
                                     keyEquivalent: "")
        appMenuItem.submenu = appMenu
        
        return appMenuItem
    }
    
    private func fileMenuItem() -> NSMenuItem
    {
        let menu = NSMenu(title: "File")
        menu.addItem(withTitle: "New...",
                     action: #selector(NSDocumentController.newDocument(_:)),
                     keyEquivalent: "n")
        
        let menuItem = NSMenuItem(title: "File",
                                  action: nil,
                                  keyEquivalent: "")
        menuItem.submenu = menu
        
        return menuItem
    }
}

import AppKit

class ApplicationMenu: NSMenu
{
    init()
    {
        super.init(title: "Application Menu")
        
        addItem(fullscreenItem)
        
        addItem(focusItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(withTitle: "Hide",
                 action: #selector(NSApplication.hide(_:)),
                 keyEquivalent: "h")
        
        addItem(withTitle: "Quit",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q")
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Toggle Fullscreen
    
    func windowChangesFullscreen(to fullscreen: Bool)
    {
        focusItem.target = fullscreen ? nil : self
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
        
        fullscreenItem.target = gonnaFocus ? nil : self
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
        item.keyEquivalent = "m"
        return item
    }()
    
    private func focusItemTitle(isFocused: Bool) -> String
    {
        return isFocused ? "Multitasking" : "Monotasking"
    }
}

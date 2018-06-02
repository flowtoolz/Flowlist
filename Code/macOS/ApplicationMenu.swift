import AppKit

class ApplicationMenu: NSMenu
{
    // MARK: - Initialization
    
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
    
    private lazy var fullscreenItem: NSMenuItem = item(fullscreenItemTitle(),
                                                       action: #selector(toggleFullscreen),
                                                       key: "f")
    
    private func fullscreenItemTitle(isFullscreen: Bool = false) -> String
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
    
    private lazy var focusItem: NSMenuItem = item(focusItemTitle(),
                                                  action: #selector(toggleFocus),
                                                  key: "m")
    
    private func focusItemTitle(isFocused: Bool = false) -> String
    {
        return isFocused ? "Multitasking" : "Monotasking"
    }
}

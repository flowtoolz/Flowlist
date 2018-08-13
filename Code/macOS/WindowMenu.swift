import AppKit
import UIToolz

class WindowMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Window")
        
        addItem(fullscreenItem)
        addItem(focusItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(windowItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Update Titles
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        windowItem.title = windowItemTitle
        
        return true
    }
    
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
    
    private lazy var fullscreenItem = item(fullscreenItemTitle(),
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
    
    private lazy var focusItem = item(focusItemTitle(),
                                      action: #selector(toggleFocus),
                                      key: "m")
    
    private func focusItemTitle(isFocused: Bool = false) -> String
    {
        return isFocused ? "Multitasking" : "Monotasking"
    }
    
    // MARK: - Toggle Window Visibility
    
    private lazy var windowItem = item("Close Window",
                                       action: #selector(showWindow),
                                       key: "w")
    
    @objc private func showWindow()
    {
        window?.toggle()
    }
    
    private var windowItemTitle: String
    {
        return (window?.isVisible ?? true) ? "Close Window" : "Show Window"
    }
    
    // MARK: - Window
    
    func set(window: Window)
    {
        self.window = window
    }
    
    private weak var window: Window?
}

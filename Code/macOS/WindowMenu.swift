import AppKit
import UIToolz
import SwiftObserver

class WindowMenu: NSMenu, Observer
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
    
    deinit { stopAllObserving() }
    
    // MARK: - Update Titles
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
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
    
    // MARK: - Window Visibility
    
    func set(window: Window)
    {
        stopObserving(self.window)
        
        observe(window)
        {
            [weak self] event in
            
            switch event
            {
            case .didNothing: break
            case .didChangeVisibility(let visible):
                self?.updateWindowItemTitle(isOpen: visible)
            }
        }
        
        self.window = window
    }
    
    private func updateWindowItemTitle(isOpen open: Bool)
    {
        windowItem.title = open ? "Close Window" : "Show Window"
    }
    
    private lazy var windowItem = MenuItem("Close Window", key: "w")
    {
        [weak self] in self?.window?.toggle()
    }
    
    private weak var window: Window?
}

// TODO: replace this an only use MenuItem. be careful: item validation breaks easily...
public extension NSMenu
{
    func item(_ title: String,
              action: Selector,
              key: String,
              modifiers: NSEvent.ModifierFlags = [.command]) -> NSMenuItem
    {
        let item = NSMenuItem()
        item.target = self
        item.title = title
        item.action = action
        item.keyEquivalent = key
        item.keyEquivalentModifierMask = modifiers
        
        return item
    }
}

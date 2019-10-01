import AppKit
import UIToolz
import SwiftObserver
import SwiftyToolz

class WindowMenu: NSMenu, NSMenuItemValidation
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Window")
        
        addItem(increaseFontSizeItem)
        addItem(decreaseFontSizeItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(darkModeItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(fullscreenItem)
        addItem(focusItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(windowItem)
        
        observeDarkMode()
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopObserving() }
    
    // MARK: - Validate Items
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard menuItem !== windowItem else { return true }
        
        guard window?.isKeyWindow ?? false else { return false }
        
        switch menuItem
        {
        case fullscreenItem: return !isMonotasking
        case focusItem: return !(window?.isFullscreen ?? false)
        case increaseFontSizeItem:
            return !TextView.isEditing.value
        case decreaseFontSizeItem:
            return !TextView.isEditing.value && Font.baseSize.latestMessage > 12
        default: return true
        }
    }
    
    // MARK: - Toggle Fullscreen
    
    func windowChangesFullscreen(to fullscreen: Bool)
    {
        fullscreenItem.title = (fullscreen ? "Leave " : "") + "Fullscreen"
    }
    
    private lazy var fullscreenItem = MenuItem("Fullscreen",
                                               key: "f",
                                               validator: self)
    {
        [weak self] in
        
        guard let window = self?.window else { return }
        
        if !window.isFullscreen { window.show() }
        
        window.toggleFullScreen(self)
    }
    
    // MARK: - Toggle Focus
    
    private func updateFocusItemTitle() {
        focusItem.title = "\(self.isMonotasking ? "Multi" : "Mono")tasking"
    }
    
    private lazy var focusItem = MenuItem("Monotasking",
                                          key: "m",
                                          validator: self)
    {
        [weak self] in
        
        guard let self = self else { return }
        
        let options: NSApplication.PresentationOptions = [.autoHideMenuBar,
                                                          .autoHideDock]
    
        if self.isMonotasking
        {
            NSApp.unhideAllApplications(self)
            NSApp.presentationOptions.remove(options)
        }
        else
        {
            NSApp.presentationOptions.insert(options)
            NSApp.hideOtherApplications(self)
        }
        
        self.isMonotasking = !self.isMonotasking
        self.updateFocusItemTitle()
    }
    
    private var isMonotasking = false
    
    // MARK: - Window Visibility
    
    func set(window: Window)
    {
        stopObserving(self.window)
        
        observe(window).unwrap()
        {
            [weak self] event in
            
            switch event
            {
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
    
    private lazy var windowItem = MenuItem("Close Window",
                                           key: "w",
                                           validator: self)
    {
        [weak self] in self?.window?.toggle()
    }
    
    private weak var window: Window?
    
    // MARK: - Changing Font Size
    
    private lazy var increaseFontSizeItem = MenuItem("Bigger Font",
                                                     key: "+",
                                                     validator: self)
    { Font.baseSize.source.int += 1 }
    
    private lazy var decreaseFontSizeItem = MenuItem("Smaller Font",
                                                     key: "-",
                                                     validator: self)
    { Font.baseSize.source.int -= 1 }
    
    // MARK: - Dark Mode
    
    private func observeDarkMode()
    {
        observe(darkMode)
        {
            [weak self] _ in
            
            guard let self = self else { return }
            
            self.darkModeItem.title = self.darkModeOptionTitle
        }
    }
    
    private lazy var darkModeItem = MenuItem(self.darkModeOptionTitle,
                                             key: "d",
                                             validator: self)
    {
        Color.isInDarkMode = !Color.isInDarkMode
    }
    
    private var darkModeOptionTitle: String
    {
        return "\(Color.isInDarkMode ? "Daylight" : "Dark") Mode"
    }
}

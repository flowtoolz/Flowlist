import AppKit
import SwiftUIToolz

class FlowlistMenu: MainMenu
{
    // MARK: - Life Cycle
    
    override init()
    {
        super.init()

        addItem(NSMenuItem(submenu: DataMenu()))
        addItem(NSMenuItem(submenu: SelectionMenu()))
        addItem(NSMenuItem(submenu: EditMenu()))
        addItem(NSMenuItem(submenu: windowMenu))
        addItem(NSMenuItem(submenu: HelpMenu()))
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Window Menu
    
    func set(window: Window) { windowMenu.set(window: window) }
    
    func windowChangesFullscreen(to fullscreen: Bool)
    {
        windowMenu.windowChangesFullscreen(to: fullscreen)
    }
    
    private let windowMenu = WindowMenu()
}

//menu.addItem(withTitle: "Select All",
//             action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
//menu.addItem(withTitle: "Copy",
//             action: #selector(NSText.copy(_:)), keyEquivalent: "c")

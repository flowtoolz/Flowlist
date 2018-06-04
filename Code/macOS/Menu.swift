import AppKit

class Menu: NSMenu
{
    // MARK: - Life Cycle
    
    init()
    {
        super.init(title: "Flowlist Menu Bar")

        addItem(NSMenuItem(with: applicationMenu))
        addItem(NSMenuItem(with: NavigationMenu()))
        addItem(NSMenuItem(with: EditMenu()))
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Appliaction Menu
    
    func windowChangesFullscreen(to fullscreen: Bool)
    {
        applicationMenu.windowChangesFullscreen(to: fullscreen)
    }
    
    private let applicationMenu = ApplicationMenu()
}

//menu.addItem(withTitle: "Select All",
//             action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
//menu.addItem(withTitle: "Copy",
//             action: #selector(NSText.copy(_:)), keyEquivalent: "c")

import AppKit

class Menu: NSMenu
{
    // MARK: - Life Cycle
    
    init()
    {
        super.init(title: "Flowlist Menu Bar")

        addItem(NSMenuItem(with: applicationMenu))
        addItem(NSMenuItem(with: SelectionMenu()))
        addItem(NSMenuItem(with: EditMenu()))
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Appliaction Menu
    
    func windowChangesFullscreen(to fullscreen: Bool)
    {
        applicationMenu.windowChangesFullscreen(to: fullscreen)
    }
    
    private let applicationMenu = ApplicationMenu()
    
    // MARK: - Avoid Space Key Equivalent Altogether For It's Unreliable
    
    override func performKeyEquivalent(with event: NSEvent) -> Bool
    {
        guard event.key != .space else { return true }
        
        return super.performKeyEquivalent(with: event)
    }
}

//menu.addItem(withTitle: "Select All",
//             action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
//menu.addItem(withTitle: "Copy",
//             action: #selector(NSText.copy(_:)), keyEquivalent: "c")

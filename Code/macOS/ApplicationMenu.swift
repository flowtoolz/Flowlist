import AppKit

class ApplicationMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Application Menu")
 
        addItem(withTitle: "Hide Flowlist",
                action: #selector(NSApplication.hide(_:)),
                keyEquivalent: "h")
        
        addItem(NSMenuItem.separator())
        
        addItem(withTitle: "Quit Flowlist",
                action: #selector(NSApplication.terminate(_:)),
                keyEquivalent: "q")
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
}

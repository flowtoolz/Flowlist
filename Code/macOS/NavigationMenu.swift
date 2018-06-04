import AppKit

class NavigationMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Navigate")
        
        addItem(goRightItem)
        addItem(goLeftItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Availability
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard !TextField.isEditing else { return false }
        
        switch menuItem
        {
        case goRightItem: return Browser.active?.canMove(.right) ?? false
        case goLeftItem: return Browser.active?.canMove(.left) ?? false
        default: return true
        }
    }
    
    // MARK: - Items
    
    private lazy var goRightItem = item("Go to Details",
                                        action: #selector(goRight),
                                        key: String(unicode: NSRightArrowFunctionKey),
                                        modifiers: [])
    @objc private func goRight() { Browser.active?.move(.right) }
    
    private lazy var goLeftItem = item("Go to Overview",
                                       action: #selector(goLeft),
                                       key: String(unicode: NSLeftArrowFunctionKey),
                                       modifiers: [])
    @objc private func goLeft() { Browser.active?.move(.left) }
}

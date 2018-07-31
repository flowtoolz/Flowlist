import AppKit

class SelectionMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Select")
        
        addItem(goUpItem)
        addItem(goDownItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(goLeftItem)
        addItem(goRightItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(selectUpItem)
        addItem(selectDownItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(selectAllItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Availability
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard !TextView.isEditing else { return false }
        
        switch menuItem
        {
        case goRightItem:
            return Browser.active?.canMove(.right) ?? false
            
        case goLeftItem:
            return Browser.active?.canMove(.left) ?? false
            
        case selectAllItem:
            return list?.numberOfTasks ?? 0 > 0
            
        case goUpItem:
            return list?.canShiftSelectionUp ?? false
            
        case goDownItem:
            return list?.canShiftSelectionDown ?? false
            
        case selectUpItem:
            return list?.canExtendSelectionUp ?? false
            
        case selectDownItem:
            return list?.canExtendSelectionDown ?? false
            
        default:
            return true
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
    
    private lazy var goUpItem = item("Go Up",
                                     action: #selector(goUp),
                                     key: String(unicode: NSUpArrowFunctionKey),
                                     modifiers: [])
    @objc private func goUp() { list?.shiftSelectionUp() }
    
    private lazy var goDownItem = item("Go Down",
                                       action: #selector(goDown),
                                       key: String(unicode: NSDownArrowFunctionKey),
                                       modifiers: [])
    @objc private func goDown() { list?.shiftSelectionDown() }
    
    private lazy var selectUpItem = item("Extend Selection Up",
                                       action: #selector(selectUp),
                                       key: String(unicode: NSUpArrowFunctionKey),
                                       modifiers: [.shift])
    @objc private func selectUp() { list?.extendSelectionUp() }
    
    private lazy var selectDownItem = item("Extend Selection Down",
                                         action: #selector(selectDown),
                                         key: String(unicode: NSDownArrowFunctionKey),
                                         modifiers: [.shift])
    @objc private func selectDown() { list?.extendSelectionDown() }
    
    private lazy var selectAllItem = item("Select All",
                                          action: #selector(selectAll),
                                          key: "a")
    @objc private func selectAll() { list?.selectAll() }
    
    private var list: SelectableList? { return Browser.active?.focusedList }
}

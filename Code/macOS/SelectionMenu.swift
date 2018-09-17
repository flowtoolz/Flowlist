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
    
    private lazy var goRightItem = MenuItem("Go to Details",
                                            key: String(unicode: NSRightArrowFunctionKey),
                                            modifiers: [],
                                            validator: self)
    {
        [weak self] in Browser.active?.move(.right)
    }
    
    private lazy var goLeftItem = MenuItem("Go to Overview",
                                           key: String(unicode: NSLeftArrowFunctionKey),
                                           modifiers: [],
                                           validator: self)
    {
        Browser.active?.move(.left)
    }
    
    private lazy var goUpItem = MenuItem("Go Up",
                                         key: String(unicode: NSUpArrowFunctionKey),
                                         modifiers: [],
                                         validator: self)
    {
        [weak self] in self?.list?.shiftSelectionUp()
    }
    
    private lazy var goDownItem = MenuItem("Go Down",
                                           key: String(unicode: NSDownArrowFunctionKey),
                                           modifiers: [],
                                           validator: self)
    {
        [weak self] in self?.list?.shiftSelectionDown()
    }
    
    private lazy var selectUpItem = MenuItem("Extend Selection Up",
                                             key: String(unicode: NSUpArrowFunctionKey),
                                             modifiers: [.shift],
                                             validator: self)
    {
        [weak self] in self?.list?.extendSelectionUp()
    }
    
    private lazy var selectDownItem = MenuItem("Extend Selection Down",
                                               key: String(unicode: NSDownArrowFunctionKey),
                                               modifiers: [.shift],
                                               validator: self)
    {
        [weak self] in self?.list?.extendSelectionDown()
    }
    
    private lazy var selectAllItem = MenuItem("Select All",
                                              key: "a",
                                              validator: self)
    {
        [weak self] in self?.list?.selectAll()
    }
    
    private var list: SelectableList? { return Browser.active?.focusedList }
}

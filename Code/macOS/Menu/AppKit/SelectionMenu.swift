import AppKit
import SwiftUIToolz

class SelectionMenu: NSMenu, NSMenuItemValidation
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
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard NSApp.mainWindow?.isKeyWindow ?? false else { return false }
        
        guard !TextView.isEditing.value else { return false }
        
        switch menuItem
        {
        case goRightItem:
            return browser.canMove(.right)
            
        case goLeftItem:
            return browser.canMove(.left)
            
        case selectAllItem:
            return browser.focusedList.count > 0
            
        case goUpItem:
            return browser.focusedList.canShiftSelectionUp
            
        case goDownItem:
            return browser.focusedList.canShiftSelectionDown
            
        case selectUpItem:
            return browser.focusedList.canExtendSelectionUp
            
        case selectDownItem:
            return browser.focusedList.canExtendSelectionDown
            
        default:
            return true
        }
    }
    
    // MARK: - Items
    
    private lazy var goRightItem = MenuItem("Go to Details",
                                            key: String(unicode: NSEvent.SpecialKey.rightArrow.rawValue),
                                            modifiers: [],
                                            validator: self)
    {
        browser.move(.right)
    }
    
    private lazy var goLeftItem = MenuItem("Go to Overview",
                                           key: String(unicode: NSEvent.SpecialKey.leftArrow.rawValue),
                                           modifiers: [],
                                           validator: self)
    {
        browser.move(.left)
    }
    
    private lazy var goUpItem = MenuItem("Go Up",
                                         key: String(unicode: NSEvent.SpecialKey.upArrow.rawValue),
                                         modifiers: [],
                                         validator: self)
    {
        browser.focusedList.shiftSelectionUp()
    }
    
    private lazy var goDownItem = MenuItem("Go Down",
                                           key: String(unicode: NSEvent.SpecialKey.downArrow.rawValue),
                                           modifiers: [],
                                           validator: self)
    {
        browser.focusedList.shiftSelectionDown()
    }
    
    private lazy var selectUpItem = MenuItem("Extend Selection Up",
                                             key: String(unicode: NSEvent.SpecialKey.upArrow.rawValue),
                                             modifiers: [.shift],
                                             validator: self)
    {
        browser.focusedList.extendSelectionUp()
    }
    
    private lazy var selectDownItem = MenuItem("Extend Selection Down",
                                               key: String(unicode: NSEvent.SpecialKey.downArrow.rawValue),
                                               modifiers: [.shift],
                                               validator: self)
    {
        browser.focusedList.extendSelectionDown()
    }
    
    private lazy var selectAllItem = MenuItem("Select All",
                                              key: "a",
                                              validator: self)
    {
        browser.focusedList.selectAll()
    }
}

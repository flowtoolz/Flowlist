import AppKit
import SwiftyToolz

class EditMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Edit")
        
        addItem(item("Add on Top",
                     action: #selector(doNothingHere),
                     key: " ",
                     modifiers: []))
        addItem(item("Add / Group",
                     action: #selector(doNothingHere),
                     key: "\n",
                     modifiers: []))
        
        addItem(item("Delete",
                     action: #selector(doNothingHere),
                     key: String(unicode: NSBackspaceCharacter),
                     modifiers: []))
        addItem(item("Paste Deleted Items",
                     action: #selector(doNothingHere),
                     key: "z"))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Move Up",
                     action: #selector(doNothingHere),
                     key: String(unicode: NSUpArrowFunctionKey)))
        addItem(item("Move Down",
                     action: #selector(doNothingHere),
                     key: String(unicode: NSDownArrowFunctionKey)))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Rename",
                     action: #selector(doNothingHere),
                     key: "\n"))
        addItem(item("Check Off",
                     action: #selector(doNothingHere),
                     key: String(unicode: NSBackspaceCharacter)))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Copy", action: #selector(doNothingHere), key: "c"))
        addItem(item("Cut", action: #selector(doNothingHere), key: "x"))
        addItem(item("Paste", action: #selector(doNothingHere), key: "v"))
        
        addItem(item("Go to Details",
                     action: #selector(goRight),
                     key: String(unicode: NSRightArrowFunctionKey),
                     modifiers: []))
        addItem(item("Go to Overview",
                     action: #selector(goLeft),
                     key: String(unicode: NSLeftArrowFunctionKey),
                     modifiers: []))
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Actions
    
    @objc private func doNothingHere() { }
    
    @objc private func goRight() { Browser.active?.move(.right) }
    
    @objc private func goLeft() { Browser.active?.move(.left) }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        if menuItem.title == "Go to Details" || menuItem.title == "Go to Overview"
        {
            return !TextField.isEditing
        }
        
        return super.validateMenuItem(menuItem)
    }
}

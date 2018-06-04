import AppKit
import SwiftyToolz

class EditMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Edit")
        
        addItem(item("Add on Top",
                     action: #selector(createTaskAtTop),
                     key: " ",
                     modifiers: []))
        addItem(item("Add / Group",
                     action: #selector(createTask),
                     key: "\n",
                     modifiers: []))
        
        addItem(item("Delete",
                     action: #selector(delete),
                     key: String(unicode: NSBackspaceCharacter),
                     modifiers: []))
        addItem(item("Paste Deleted Items",
                     action: #selector(undo),
                     key: "z"))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Move Up",
                     action: #selector(moveTaskUp),
                     key: String(unicode: NSUpArrowFunctionKey)))
        addItem(item("Move Down",
                     action: #selector(moveTaskDown),
                     key: String(unicode: NSDownArrowFunctionKey)))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Rename",
                     action: #selector(renameTask),
                     key: "\n"))
        addItem(item("Check Off",
                     action: #selector(checkOff),
                     key: String(unicode: NSBackspaceCharacter)))
        
        addItem(NSMenuItem.separator())
        
        addItem(item("Copy", action: #selector(copyTasks), key: "c"))
        addItem(item("Cut", action: #selector(cut), key: "x"))
        addItem(item("Paste", action: #selector(paste), key: "v"))
        
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
    
    @objc private func goRight() { Browser.active?.move(.right) }
    @objc private func goLeft() { Browser.active?.move(.left) }
    @objc private func createTask() { Browser.active?.createTask() }
    @objc private func createTaskAtTop() { Browser.active?.createTaskAtTop() }
    @objc private func renameTask() { Browser.active?.renameTask() }
    @objc private func checkOff() { Browser.active?.checkOff() }
    @objc private func delete() { Browser.active?.delete() }
    @objc private func moveTaskUp() { Browser.active?.moveTaskUp() }
    @objc private func moveTaskDown() { Browser.active?.moveTaskDown() }
    @objc private func copyTasks() { Browser.active?.copy() }
    @objc private func cut() { Browser.active?.cut() }
    @objc private func paste() { Browser.active?.paste() }
    @objc private func undo() { Browser.active?.undo() }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        return !TextField.isEditing
    }
}

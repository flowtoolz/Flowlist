import AppKit
import SwiftyToolz

class EditMenu: NSMenu
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Edit")
        
        addItem(createTaskAtTopItem)
        addItem(createTaskItem)
        
        addItem(deleteItem)
        addItem(undoItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(moveUpItem)
        addItem(moveDownItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(renameTaskItem)
        addItem(checkOffItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(copyItem)
        addItem(cutItem)
        addItem(pasteItem)
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Availability
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        return !TextField.isEditing
    }
    
    // MARK: - Items
    
    private lazy var createTaskItem = item("Add / Group",
                                           action: #selector(createTask),
                                           key: "\n",
                                           modifiers: [])
    @objc private func createTask() { Browser.active?.createTask() }
    
    private lazy var createTaskAtTopItem = item("Add on Top",
                                                action: #selector(createTaskAtTop),
                                                key: " ",
                                                modifiers: [])
    @objc private func createTaskAtTop() { Browser.active?.createTaskAtTop() }
    
    private lazy var renameTaskItem = item("Rename",
                                           action: #selector(renameTask),
                                           key: "\n")
    @objc private func renameTask() { Browser.active?.renameTask() }
    
    private lazy var checkOffItem = item("Check Off",
                                         action: #selector(checkOff),
                                         key: String(unicode: NSBackspaceCharacter))
    @objc private func checkOff() { Browser.active?.checkOff() }
    
    private lazy var deleteItem = item("Delete",
                                       action: #selector(delete),
                                       key: String(unicode: NSBackspaceCharacter),
                                       modifiers: [])
    @objc private func delete() { Browser.active?.delete() }
    
    private lazy var moveUpItem = item("Move Up",
                                       action: #selector(moveTaskUp),
                                       key: String(unicode: NSUpArrowFunctionKey))
    @objc private func moveTaskUp() { Browser.active?.moveTaskUp() }
    
    private lazy var moveDownItem = item("Move Down",
                                         action: #selector(moveTaskDown),
                                         key: String(unicode: NSDownArrowFunctionKey))
    @objc private func moveTaskDown() { Browser.active?.moveTaskDown() }
    
    private lazy var copyItem = item("Copy", action: #selector(copyTasks), key: "c")
    @objc private func copyTasks() { Browser.active?.copy() }
    
    private lazy var cutItem = item("Cut", action: #selector(cut), key: "x")
    @objc private func cut() { Browser.active?.cut() }
    
    private lazy var pasteItem = item("Paste", action: #selector(paste), key: "v")
    @objc private func paste() { Browser.active?.paste() }
    
    private lazy var undoItem = item("Paste Deleted Items",
                                     action: #selector(undo),
                                     key: "z")
    @objc private func undo() { Browser.active?.undo() }
}

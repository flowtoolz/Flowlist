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
        
        addItem(renameItem)
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
        guard !TextField.isEditing else { return false }
        
        switch menuItem
        {
        case renameItem, checkOffItem, deleteItem, copyItem, cutItem:
            return numberOfSelectedTasks > 0
        case moveUpItem, moveDownItem:
            return numberOfSelectedTasks == 1
        case pasteItem:
            return clipboard.count > 0
        case undoItem:
            return list?.root?.hasRemovedSubtasks ?? false
        default:
            return list != nil
        }
    }
    
    private var numberOfSelectedTasks: Int { return list?.selection.count ?? 0 }
    
    // MARK: - Items
    
    private lazy var createTaskItem = item("Add (Group)",
                                           action: #selector(createTask),
                                           key: "\n",
                                           modifiers: [])
    @objc private func createTask() { list?.createTask() }
    
    private lazy var createTaskAtTopItem = item("Add on Top",
                                                action: #selector(createTaskAtTop),
                                                key: " ",
                                                modifiers: [])
    @objc private func createTaskAtTop() { list?.create(at: 0) }
    
    private lazy var renameItem = item("Rename",
                                       action: #selector(renameTask),
                                       key: "\n")
    @objc private func renameTask() { list?.editTitle() }
    
    private lazy var checkOffItem = item("Check Off",
                                         action: #selector(checkOff),
                                         key: String(unicode: NSBackspaceCharacter))
    @objc private func checkOff() { list?.checkOffFirstSelectedUncheckedTask() }
    
    private lazy var deleteItem = item("Delete",
                                       action: #selector(delete),
                                       key: String(unicode: NSBackspaceCharacter),
                                       modifiers: [])
    @objc private func delete() { list?.removeSelectedTasks() }
    
    private lazy var moveUpItem = item("Move Up",
                                       action: #selector(moveTaskUp),
                                       key: String(unicode: NSUpArrowFunctionKey))
    @objc private func moveTaskUp() { list?.moveSelectedTask(-1) }
    
    private lazy var moveDownItem = item("Move Down",
                                         action: #selector(moveTaskDown),
                                         key: String(unicode: NSDownArrowFunctionKey))
    @objc private func moveTaskDown() { list?.moveSelectedTask(1) }
    
    private lazy var copyItem = item("Copy", action: #selector(copyTasks), key: "c")
    @objc private func copyTasks() { list?.copy() }
    
    private lazy var cutItem = item("Cut", action: #selector(cut), key: "x")
    @objc private func cut() { list?.cut() }
    
    private lazy var pasteItem = item("Paste", action: #selector(paste), key: "v")
    @objc private func paste() { list?.paste() }
    
    private lazy var undoItem = item("Paste Deleted Items",
                                     action: #selector(undo),
                                     key: "z")
    @objc private func undo() { list?.undoLastRemoval() }
    
    private var list: SelectableList? { return Browser.active?.focusedList }
}

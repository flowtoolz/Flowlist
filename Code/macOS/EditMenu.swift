import AppKit
import UIObserver
import SwiftyToolz
import SwiftObserver

class EditMenu: NSMenu, Observer
{
    // MARK: - Initialization
    
    init()
    {
        super.init(title: "Edit")
        
        addItem(createAtTopItem)
        addItem(createItem)
        
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
        
        observe(keyboard)
        {
            [unowned self] in
            
            switch $0.key
            {
            case .space:
                if !TextField.isEditing { self.list?.create(at: 0) }
                
            case .unknown:
                guard $0.cmd else { break }
                
                switch $0.characters
                {
                case "l": self.list?.debug()
                case "t": store.root.debug()
                default: break
                }
                
            default: break
            }
        }
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Action Availability
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard !TextField.isEditing else { return false }
        
        let selected = numberOfSelectedTasks
        let deleted = list?.root?.numberOfRemovedSubtasks ?? 0
        let systemPasteboard = systemPasteboardHasText
        updateTitles(numberOfDeletedItems: deleted,
                     numberOfSelectedItems: selected,
                     systemPasteboardHasText: systemPasteboard)
        
        switch menuItem
        {
        case renameItem, checkOffItem, deleteItem, copyItem, cutItem: return selected > 0
        case moveUpItem, moveDownItem: return selected == 1
        case pasteItem: return clipboard.count > 0 || systemPasteboard
        case undoItem: return deleted > 0
        default: return list != nil
        }
    }
    
    private var numberOfSelectedTasks: Int { return list?.selection.count ?? 0 }
    
    // MARK: - Items
    
    private func updateTitles(numberOfDeletedItems deleted: Int,
                              numberOfSelectedItems selected: Int,
                              systemPasteboardHasText systemPasteboard: Bool)
    {
        createItem.title = selected > 1 ? "Group \(selected) Items" : "Add Item"
        renameItem.title = selected > 1 ? "Rename \(selected) Items" : "Rename Item"
        checkOffItem.title = selected > 1 ? "Check Off 1st of \(selected) Items" : "Check Item Off"
        deleteItem.title = selected > 1 ? "Delete \(selected) Items" : "Delete Item"
        copyItem.title = selected > 1 ? "Copy \(selected) Items" : "Copy Item"
        cutItem.title = selected > 1 ? "Cut \(selected) Items" : "Cut Item"
        
        if systemPasteboard
        {
            pasteItem.title = "Paste Items from Text"
        }
        else if clipboard.count > 1
        {
            pasteItem.title = "Paste \(clipboard.count) Items"
        }
        else
        {
            pasteItem.title = "Paste Item"
        }
        
        undoItem.title = deleted > 1 ? "Paste \(deleted) Deleted Items" : "Paste Deleted Item"
    }
    
    private lazy var createItem = item("Add Item",
                                       action: #selector(create),
                                       key: "\n",
                                       modifiers: [])
    @objc private func create() { list?.createTask() }
    
    private lazy var createAtTopItem = item("Add Item on Top",
                                            action: #selector(createAtTop),
                                            key: " ",
                                            modifiers: [])
    @objc private func createAtTop() { }
    
    private lazy var renameItem = item("Rename Item",
                                       action: #selector(rename),
                                       key: "\n")
    @objc private func rename() { list?.editTitle() }
    
    private lazy var checkOffItem = item("Check Item Off",
                                         action: #selector(checkOff),
                                         key: String(unicode: NSBackspaceCharacter))
    @objc private func checkOff() { list?.checkOffFirstSelectedUncheckedTask() }
    
    private lazy var deleteItem = item("Delete Item",
                                       action: #selector(delete),
                                       key: String(unicode: NSBackspaceCharacter),
                                       modifiers: [])
    @objc private func delete() { list?.removeSelectedTasks() }
    
    private lazy var moveUpItem = item("Move Item Up",
                                       action: #selector(moveUp),
                                       key: String(unicode: NSUpArrowFunctionKey))
    @objc private func moveUp() { list?.moveSelectedTask(-1) }
    
    private lazy var moveDownItem = item("Move Item Down",
                                         action: #selector(moveDown),
                                         key: String(unicode: NSDownArrowFunctionKey))
    @objc private func moveDown() { list?.moveSelectedTask(1) }
    
    private lazy var copyItem = item("Copy Item",
                                     action: #selector(copyTasks),
                                     key: "c")
    @objc private func copyTasks()
    {
        list?.copy()
        NSPasteboard.general.clearContents()
    }
    
    private lazy var cutItem = item("Cut Item",
                                    action: #selector(cut),
                                    key: "x")
    @objc private func cut()
    {
        list?.cut()
        NSPasteboard.general.clearContents()
    }
    
    private lazy var pasteItem = item("Paste Item",
                                      action: #selector(paste),
                                      key: "v")
    @objc private func paste()
    {
        if systemPasteboardHasText
        {
            list?.pasteFromSystemPasteboard()
            NSPasteboard.general.clearContents()
        }
        else if clipboard.count > 0
        {
            list?.pasteFromClipboard()
        }
    }
    
    private lazy var undoItem = item("Paste Deleted Item",
                                     action: #selector(undo),
                                     key: "z")
    @objc private func undo() { list?.undoLastRemoval() }
    
    private var list: SelectableList? { return Browser.active?.focusedList }
}

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
        
        addItem(NSMenuItem.separator())
        
        addItem(createItem)
        addItem(renameItem)
        addItem(deleteItem)
        addItem(undoItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(moveUpItem)
        addItem(moveDownItem)
        addItem(checkOffItem)
        addItem(inProgressItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(copyItem)
        addItem(cutItem)
        addItem(pasteItem)
        
        addItem(NSMenuItem.separator())
        
        addItem(tagItem)
        
        observe(keyboard)
        {
            [weak self] in
            
            if $0.key == .space { self?.createAtTop() }
        }
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    deinit { stopAllObserving() }
    
    // MARK: - Action Availability
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard !TextView.isEditing else { return false }
        
        let list = Browser.active?.focusedList
        
        let selected = numberOfSelectedTasks
        let deleted = list?.root?.numberOfRemovedSubtasks ?? 0
        let systemPasteboard = systemPasteboardHasText
        updateTitles(numberOfDeletedItems: deleted,
                     numberOfSelectedItems: selected,
                     systemPasteboardHasText: systemPasteboard)
        
        switch menuItem
        {
        case createItem, createAtTopItem:
            return !reachedTaskNumberLimit
            
        case renameItem, checkOffItem, deleteItem, cutItem, inProgressItem, tagItem:
            return selected > 0
            
        case copyItem:
            return selected > 0 && !reachedTaskNumberLimit
            
        case moveUpItem:
            return list?.canMoveItems(up: true) ?? false
            
        case moveDownItem:
            return list?.canMoveItems(up: false) ?? false
            
        case pasteItem:
            return !reachedTaskNumberLimit && (clipboard.count > 0 || systemPasteboard)
            
        case undoItem:
            return deleted > 0 && !reachedTaskNumberLimit
            
        default:
            return list != nil
        }
    }
    
    private var numberOfSelectedTasks: Int
    {
        return Browser.active?.focusedList.selection.count ?? 0
    }
    
    // MARK: - Items
    
    private func updateTitles(numberOfDeletedItems deleted: Int,
                              numberOfSelectedItems selected: Int,
                              systemPasteboardHasText systemPasteboard: Bool)
    {
        let task = Browser.active?.focusedList.firstSelectedTask
        
        createItem.title = selected > 1 ? "Group \(selected) Items" : "Add New Item"
        renameItem.title = selected > 1 ? "Rename 1st of \(selected) Items" : "Rename Item"
        
        let checkAction = task?.isDone ?? false ? "Uncheck" : "Check Off"
        checkOffItem.title = selected > 1 ? "\(checkAction) 1st of \(selected) Items" : "\(checkAction) Item"
        
        let progressAction = task?.isInProgress ?? false ? "Pause" : "Start"
        inProgressItem.title = selected > 1 ? "\(progressAction) 1st of \(selected) Items" : "\(progressAction) Item"

        deleteItem.title = selected > 1 ? "Delete \(selected) Items" : "Delete Item"
        copyItem.title = selected > 1 ? "Copy \(selected) Items" : "Copy Item"
        cutItem.title = selected > 1 ? "Cut \(selected) Items" : "Cut Item"
        
        if systemPasteboard
        {
            pasteItem.title = "Paste Text as Items"
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
        
        tagItem.title = selected > 1 ? "Tag \(selected) Items" : "Tag Item"
    }
    
    private lazy var createItem = MenuItem("Add New Item",
                                           key: "\n",
                                           modifiers: [],
                                           validator: self)
    {
        Browser.active?.focusedList.createTask()
    }
    
    private lazy var createAtTopItem = MenuItem("Add New Item on Top",
                                                key: " ",
                                                modifiers: [],
                                                validator: self)
    {
        [weak self] in self?.createAtTop()
    }
    
    private func createAtTop()
    {
        if !TextView.isEditing && !reachedTaskNumberLimit
        {
            Browser.active?.focusedList.create(at: 0)
        }
    }
    
    private lazy var renameItem = MenuItem("Rename Item",
                                           key: "\n",
                                           validator: self)
    {
        Browser.active?.focusedList.editTitle()
    }
    
    private lazy var checkOffItem = MenuItem("Check Off Item",
                                             key: String(unicode: NSLeftArrowFunctionKey),
                                             validator: self)
    {
        Browser.active?.focusedList.toggleDoneStateOfFirstSelectedTask()
    }
    
    private lazy var inProgressItem = MenuItem("Start Item",
                                               key: String(unicode: NSRightArrowFunctionKey),
                                               validator: self)
    {
        Browser.active?.focusedList.toggleInProgressStateOfFirstSelectedTask()
    }
    
    private lazy var deleteItem = MenuItem("Delete Item",
                                           key: String(unicode: NSBackspaceCharacter),
                                           modifiers: [],
                                           validator: self)
    {
        Browser.active?.focusedList.removeSelectedTasks()
    }
    
    private lazy var moveUpItem = MenuItem("Move Item Up",
                                           key: String(unicode: NSUpArrowFunctionKey),
                                           validator: self)
    {
        Browser.active?.focusedList.moveSelectedTask(-1)
    }
    
    private lazy var moveDownItem = MenuItem("Move Item Down",
                                             key: String(unicode: NSDownArrowFunctionKey),
                                             validator: self)
    {
        Browser.active?.focusedList.moveSelectedTask(1)
    }
    
    
    private lazy var copyItem = MenuItem("Copy Item",
                                         key: "c",
                                         validator: self)
    {
        Browser.active?.focusedList.copy()
        NSPasteboard.general.clearContents()
    }
    
    private lazy var cutItem = MenuItem("Cut Item",
                                        key: "x",
                                        validator: self)
    {
        Browser.active?.focusedList.cut()
        NSPasteboard.general.clearContents()
    }
    
    private lazy var pasteItem = MenuItem("Paste Item",
                                          key: "v",
                                          validator: self)
    {
        if systemPasteboardHasText
        {
            Browser.active?.focusedList.pasteFromSystemPasteboard()
            NSPasteboard.general.clearContents()
        }
        else if clipboard.count > 0
        {
            Browser.active?.focusedList.pasteFromClipboard()
        }
    }
    
    private lazy var undoItem = MenuItem("Paste Deleted Item",
                                         key: "z",
                                         validator: self)
    {
        Browser.active?.focusedList.undoLastRemoval()
    }
    
    private lazy var tagItem: NSMenuItem =
    {
        let images = [#imageLiteral(resourceName: "tag_red"), #imageLiteral(resourceName: "tag_orange"), #imageLiteral(resourceName: "tag_yellow"), #imageLiteral(resourceName: "tag_green"), #imageLiteral(resourceName: "tag_blue"), #imageLiteral(resourceName: "tag_purple"), #imageLiteral(resourceName: "tag_none")]
        
        let subMenu = NSMenu()
        
        for i in 0 ..< 7
        {
            let tag = Task.Tag(rawValue: i)
            
            let name = tag?.string ?? "None"
            
            let item = MenuItem(name, key: "\((i + 1) % 7)", modifiers: [])
            {
                Browser.active?.focusedList.set(tag: tag)
            }
            
            item.image = images[i]
            
            subMenu.addItem(item)
        }
        
        let mainItem = MenuItem("Tag Item", validator: self) {}
        
        mainItem.submenu = subMenu
        
        return mainItem
    }()
}

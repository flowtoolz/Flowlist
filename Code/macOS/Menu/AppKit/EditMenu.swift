import AppKit
import SwiftUIToolz
import SwiftyToolz
import SwiftObserver

class EditMenu: NSMenu, NSMenuItemValidation, Observer
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
        
        observe(browser)
        {
            [weak self] event in
            
            if case .selectionChanged(let list) = event,
                list === browser.focusedList
            {
                self?.update()
            }
        }
        
        observe(TextView.isEditing)
        {
            [weak self] _ in self?.update()
        }
    }
    
    required init(coder decoder: NSCoder) { fatalError() }
    
    // MARK: - Action Availability
    
    func validateMenuItem(_ menuItem: NSMenuItem) -> Bool
    {
        guard NSApp.mainWindow?.isKeyWindow ?? false else { return false }
        
        guard !TextView.isEditing.value else { return false }
        
        let selected = numberOfSelectedItems
        let deleted = browser.focusedList.root?.deletionStack.last?.count ?? 0
        let systemPasteboard = systemPasteboardHasText
        updateTitles(numberOfDeletedItems: deleted,
                     numberOfSelectedItems: selected,
                     systemPasteboardHasText: systemPasteboard)
        
        switch menuItem
        {
        case createItem, createAtTopItem:
            return !reachedItemNumberLimit
            
        case renameItem, checkOffItem, deleteItem, cutItem, inProgressItem, tagItem:
            return selected > 0
            
        case copyItem:
            return selected > 0 && !reachedItemNumberLimit
            
        case moveUpItem:
            return browser.focusedList.canMoveItems(up: true)
            
        case moveDownItem:
            return browser.focusedList.canMoveItems(up: false)
            
        case pasteItem:
            return !reachedItemNumberLimit && (clipboard.count > 0 || systemPasteboard)
            
        case undoItem:
            return deleted > 0 && !reachedItemNumberLimit
            
        default: return true
        }
    }
    
    private var numberOfSelectedItems: Int
    {
        browser.focusedList.selectedIndexes.count
    }
    
    // MARK: - Items
    
    private func updateTitles(numberOfDeletedItems deleted: Int,
                              numberOfSelectedItems selected: Int,
                              systemPasteboardHasText systemPasteboard: Bool)
    {
        let list = browser.focusedList
        let item = list[list.selectedIndexes.first]
        
        createItem.title = selected > 1 ? "Group \(selected) Items" : "Add New Item"
        renameItem.title = selected > 1 ? "Rename 1st of \(selected) Items" : "Rename Item"
        
        let checkAction = item?.isDone ?? false ? "Uncheck" : "Check Off"
        checkOffItem.title = selected > 1 ? "\(checkAction) 1st of \(selected) Items" : "\(checkAction) Item"
        
        let progressAction = item?.isInProgress ?? false ? "Pause" : "Start"
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
        browser.focusedList.createItem()
    }
    
    private lazy var createAtTopItem = MenuItem("Add New Item on Top",
                                                key: " ",
                                                modifiers: [],
                                                validator: self)
    {
        [weak self] in self?.dummyFunction()
    }
    
    private func dummyFunction() {}
    
    private lazy var renameItem = MenuItem("Rename Item",
                                           key: "\n",
                                           validator: self)
    {
        browser.focusedList.editText()
    }
    
    private lazy var checkOffItem = MenuItem("Check Off Item",
                                             key: .leftArrow,
                                             validator: self)
    {
        browser.focusedList.toggleDoneStateOfFirstSelectedItem()
    }
    
    private lazy var inProgressItem = MenuItem("Start Item",
                                               key: .rightArrow,
                                               validator: self)
    {
        
        
        browser.focusedList.toggleInProgressStateOfFirstSelectedItem()
    }
    
    private lazy var deleteItem = MenuItem("Delete Item",
                                           key: .backspace,
                                           modifiers: [],
                                           validator: self)
    {
        browser.focusedList.removeSelectedItems()
    }
    
    private lazy var moveUpItem = MenuItem("Move Item Up",
                                           key: .upArrow,
                                           validator: self)
    {
        browser.focusedList.moveSelectedItem(-1)
    }
    
    private lazy var moveDownItem = MenuItem("Move Item Down",
                                             key: .downArrow,
                                             validator: self)
    {
        browser.focusedList.moveSelectedItem(1)
    }
    
    
    private lazy var copyItem = MenuItem("Copy Item",
                                         key: "c",
                                         validator: self)
    {
        browser.focusedList.copy()
        NSPasteboard.general.clearContents()
    }
    
    private lazy var cutItem = MenuItem("Cut Item",
                                        key: "x",
                                        validator: self)
    {
        browser.focusedList.cut()
        NSPasteboard.general.clearContents()
    }
    
    private lazy var pasteItem = MenuItem("Paste Item",
                                          key: "v",
                                          validator: self)
    {
        if systemPasteboardHasText
        {
            browser.focusedList.pasteFromSystemPasteboard()
            NSPasteboard.general.clearContents()
        }
        else if clipboard.count > 0
        {
            browser.focusedList.pasteFromClipboard()
        }
    }
    
    private lazy var undoItem = MenuItem("Paste Deleted Item",
                                         key: "z",
                                         validator: self)
    {
        browser.focusedList.undoLastRemoval()
    }
    
    private lazy var tagItem: NSMenuItem =
    {
        let images = [#imageLiteral(resourceName: "tag_red"), #imageLiteral(resourceName: "tag_orange"), #imageLiteral(resourceName: "tag_yellow"), #imageLiteral(resourceName: "tag_green"), #imageLiteral(resourceName: "tag_blue"), #imageLiteral(resourceName: "tag_purple"), #imageLiteral(resourceName: "tag_none")]
        
        let subMenu = NSMenu()
        
        for i in 0 ..< 7
        {
            let tag = ItemData.Tag(integer: i)
            
            let name = tag?.string ?? "None"
            
            let item = MenuItem(name, key: "\((i + 1) % 7)", modifiers: [])
            {
                browser.focusedList.set(tag: tag)
            }
            
            item.image = images[i]
            
            subMenu.addItem(item)
        }
        
        let mainItem = MenuItem("Tag Item", validator: self) {}
        
        mainItem.submenu = subMenu
        
        return mainItem
    }()
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

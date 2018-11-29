import SwiftObserver
import SwiftyToolz

extension List
{
    // MARK: - Tag
    
    func set(tag: ItemData.Tag?)
    {
        let selected = selectedIndexes
        
        guard !selected.isEmpty else { return }
        
        if selected.count == 1
        {
            if let data = self[selected[0]]?.data
            {
                data.tag <- data.tag.value != tag ? tag : nil
            }
        }
        else
        {
            selected.forEach { self[$0]?.data.tag <- tag }
        }
    }

    // MARK: - Create
    
    func createItem()
    {
        if selectedIndexes.count < 2
        {
            createBelowSelection()
        }
        else
        {
            groupSelectedItems()
        }
    }
    
    func groupSelectedItems()
    {
        let indexes = selectedIndexes
        
        guard indexes.count > 1 else
        {
            log(warning: "Tried to group less than 2 selected items.")
            return
        }
        
        indexes.forEach
        {
            self[$0]?.isFocused = false
            self[$0]?.isSelected = false
        }
        
        let data = ItemData()
        data.state <- root?.highestPriorityState(at: indexes)
        
        let item = Item(data: data)
        
        if let groupIndex = indexes.first,
            let _ = root?.groupNodes(at: indexes, as: item)
        {
            setSelectionWithItemsListed(at: [groupIndex])
        }
    }
    
    func createBelowSelection()
    {
        create(at: newIndexBelowSelection)
    }
    
    func create(at index: Int)
    {
        guard let _ = root?.createSubitem(at: index) else { return }
        
        setSelectionWithItemsListed(at: [index])
    }
    
    // MARK: - Paste
    
    func paste(_ items: [Item])
    {
        items.forEach { $0.isFocused = isFocused.value ?? false }
        
        let index = newIndexBelowSelection
        
        guard root?.insert(items, at: index) ?? false else { return }
        
        let pastedIndexes = Array(index ..< index + items.count)
        
        setSelectionWithItemsListed(at: pastedIndexes)
    }
    
    // MARK: - Remove
    
    @discardableResult
    func removeSelectedItems() -> Bool
    {
        let indexes = selectedIndexes
        
        deselectItems(at: indexes)
        
        guard let root = root,
            let firstSelectedIndex = indexes.first,
            let removedItems = root.removeNodes(from: indexes),
            removedItems.count > 0
        else
        {
            return false
        }
        
        selectAfterRemoval(from: firstSelectedIndex)
        
        return true
    }
    
    func selectAfterRemoval(from index: Int)
    {
        guard !(root?.isLeaf ?? true) else { return }
        
        setSelectionWithItemsListed(at: [max(index - 1, 0)])
    }
    
    func undoLastRemoval()
    {
        guard let items = root?.deletionStack.popLast() else { return }
        
        paste(items)
    }
    
    var newIndexBelowSelection: Int
    {
        return (selectedIndexes.last ?? -1) + 1
    }
    
    // MARK: - Toggle States
    
    func toggleInProgressStateOfFirstSelectedItem()
    {
        let indexes = selectedIndexes
        
        guard let firstSelectedIndex = indexes.first,
            let item = self[firstSelectedIndex]
        else { return }
        
        if indexes.count > 1
        {
            deselectItems(at: [firstSelectedIndex])
        }
        
        item.data.state <- !item.isInProgress ? .inProgress : nil
    }
    
    func toggleDoneStateOfFirstSelectedItem()
    {
        let indexes = selectedIndexes
        
        guard let firstSelectedIndex = indexes.first,
            let item = self[firstSelectedIndex]
        else
        {
            return
        }
        
        let newSelectedIndex = nextSelectedIndexAfterCheckingOff(at: firstSelectedIndex)
        
        let newState: ItemData.State? = !item.isDone ? .done : nil
        
        if indexes.count == 1,
            newState == .done,
            let newSelectedIndex = newSelectedIndex
        {
            setSelectionWithItemsListed(at: [newSelectedIndex])
        }
        else if indexes.count > 1
        {
            deselectItems(at: [firstSelectedIndex])
        }
        
        item.data.state <- newState
    }
    
    private func nextSelectedIndexAfterCheckingOff(at index: Int) -> Int?
    {
        for i in index + 1 ..< count
        {
            guard let item = self[i] else { continue }
            
            if item.isOpen { return i }
        }
        
        for i in (0 ..< index).reversed()
        {
            guard let item = self[i] else { continue }
            
            if item.isOpen { return i }
        }
        
        return nil
    }
    
    // MARK: - Move
    
    func canMoveItems(up: Bool) -> Bool
    {
        let indexes = selectedIndexes
        
        guard indexes.count == 1, let selected = indexes.first else
        {
            return false
        }
        
        if up && selected == 0 { return false }
        
        if !up && selected == count - 1 { return false }
        
        return true
    }
    
    @discardableResult
    func moveSelectedItem(_ positions: Int) -> Bool
    {
        let indexes = selectedIndexes
        
        guard positions != 0, let root = root, indexes.count == 1 else
        {
            return false
        }
        
        let selectedIndex = indexes[0]
        
        return root.moveNode(from: selectedIndex,
                                to: selectedIndex + positions)
    }
    
    // MARK: - Edit Text
    
    func editText()
    {
        guard let index = selectedIndexes.first else { return }
        
        editText(at: index)
    }
}

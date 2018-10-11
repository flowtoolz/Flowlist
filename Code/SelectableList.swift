import SwiftObserver
import SwiftyToolz

// MARK: - Tags

extension SelectableList
{
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
            for selectedindex in selected
            {
                self[selectedindex]?.data?.tag <- tag
            }
        }
    }
}

// MARK: -

class SelectableList: List
{
    // MARK: - Create
    
    func createTask()
    {
        if selectedIndexes.count < 2
        {
            createBelowSelection()
        }
        else
        {
            groupSelectedTasks()
        }
    }
    
    func groupSelectedTasks()
    {
        let indexes = selectedIndexes
        
        guard indexes.count > 1 else
        {
            log(warning: "Tried to group less than 2 selected tasks.")
            return
        }
        
        let groupState = root?.highestPriorityState(at: indexes)
        
        if let groupIndex = indexes.first,
            let group = root?.groupNodes(at: indexes)
        {
            setSelectionWithTasksListed(at: [groupIndex])
            
            let data = ItemData()
            data.state <- groupState
            group.data = data
            group.data?.send(.wantTextInput)
        }
    }
    
    func createBelowSelection()
    {
        create(at: newIndexBelowSelection)
    }
    
    func create(at index: Int)
    {
        guard let _ = root?.createSubitem(at: index) else { return }
        
        setSelectionWithTasksListed(at: [index])
    }
    
    // MARK: - Paste
    
    func paste(_ tasks: [Item])
    {
        let index = newIndexBelowSelection
        
        guard root?.insert(tasks, at: index) ?? false else { return }
        
        let pastedIndexes = Array(index ..< index + tasks.count)
        
        setSelectionWithTasksListed(at: pastedIndexes)
    }
    
    // MARK: - Remove
    
    @discardableResult
    func removeSelectedTasks() -> Bool
    {
        let indexes = selectedIndexes
        
        guard let root = root,
            let firstSelectedIndex = indexes.first,
            let removedTasks = root.removeNodes(from: indexes),
            removedTasks.count > 0
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
        
        setSelectionWithTasksListed(at: [max(index - 1, 0)])
    }
    
    func undoLastRemoval()
    {
        guard let tasks = root?.lastRemoved.copiesOfStoredObjects else
        {
            return
        }
        
        paste(tasks)
        
        root?.lastRemoved.removeAll()
    }
    
    var newIndexBelowSelection: Int
    {
        return (selectedIndexes.last ?? -1) + 1
    }
    
    // MARK: - Toggle States
    
    func toggleInProgressStateOfFirstSelectedTask()
    {
        let indexes = selectedIndexes
        
        guard let firstSelectedIndex = indexes.first,
            let task = self[firstSelectedIndex]
        else { return }
        
        if indexes.count > 1
        {
            deselectItems(at: [firstSelectedIndex])
        }
        
        task.data?.state <- !task.isInProgress ? .inProgress : nil
    }
    
    func toggleDoneStateOfFirstSelectedTask()
    {
        let indexes = selectedIndexes
        
        guard let firstSelectedIndex = indexes.first,
            let task = self[firstSelectedIndex]
        else
        {
            return
        }
        
        let newSelectedIndex = nextSelectedIndexAfterCheckingOff(at: firstSelectedIndex)
        
        let newState: ItemData.State? = !task.isDone ? .done : nil
        
        if indexes.count == 1,
            newState == .done,
            let newSelectedIndex = newSelectedIndex
        {
            setSelectionWithTasksListed(at: [newSelectedIndex])
        }
        else if indexes.count > 1
        {
            deselectItems(at: [firstSelectedIndex])
        }
        
        task.data?.state <- newState
    }
    
    private func nextSelectedIndexAfterCheckingOff(at index: Int) -> Int?
    {
        for i in index + 1 ..< count
        {
            guard let task = self[i] else { continue }
            
            if task.isOpen { return i }
        }
        
        for i in (0 ..< index).reversed()
        {
            guard let task = self[i] else { continue }
            
            if task.isOpen { return i }
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
    func moveSelectedTask(_ positions: Int) -> Bool
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
    
    // MARK: - Edit Title
    
    func editTitle()
    {
        guard let index = selectedIndexes.first else { return }
        
        editTitle(at: index)
    }
    
    // MARK: - Manage the Selection
    
    func select()
    {
        if count > 0 && selectedIndexes.count == 0
        {
            setSelectionWithTasksListed(at: [0])
        }
    }
    
    func selectAll()
    {
        setSelectionWithTasksListed(at: Array(0 ..< count))
    }
    
    var canShiftSelectionUp: Bool
    {
        return count > 0 && selectedIndexes != [0]
    }
    
    func shiftSelectionUp()
    {
        if let firstIndex = selectedIndexes.first, firstIndex > 0
        {
            setSelectionWithTasksListed(at: [firstIndex - 1])
        }
        else if count > 0
        {
            setSelectionWithTasksListed(at: [0])
        }
    }
    
    var canShiftSelectionDown: Bool
    {
        return count > 0 && selectedIndexes != [count - 1]
    }
    
    func shiftSelectionDown()
    {
        if let lastIndex = selectedIndexes.last, lastIndex + 1 < count
        {
            setSelectionWithTasksListed(at: [lastIndex + 1])
            return
        }
        else if count > 0
        {
            setSelectionWithTasksListed(at: [count - 1])
        }
    }
    
    var canExtendSelectionUp: Bool
    {
        guard let index = selectedIndexes.first, index > 0 else
        {
            return false
        }
        
        return true
    }
    
    func extendSelectionUp()
    {
        guard let index = selectedIndexes.first, index > 0 else
        {
            return
        }
        
        selectTask(at: index - 1)
    }
    
    var canExtendSelectionDown: Bool
    {
        guard let index = selectedIndexes.last, index + 1 < count else
        {
            return false
        }
        
        return true
    }
    
    func extendSelectionDown()
    {
        guard let index = selectedIndexes.last, index + 1 < count else
        {
            return
        }
        
        selectTask(at: index + 1)
    }
    
    var firstSelectedTask: Item?
    {
        guard let index = selectedIndexes.first else { return nil }
        
        return self[index]
    }
    
    override func received(_ edit: Item.Edit,
                           from root: Item)
    {
        super.received(edit, from: root)
        
        if case .remove(_, let indexes) = edit
        {
            deselectItems(at: indexes)
        }
    }
    
    var selectedIndexes: [Int]
    {
        var selected = [Int]()
        
        for index in 0 ..< count
        {
            if self[index]?.data?.isSelected.latestUpdate ?? false
            {
                selected.append(index)
            }
        }
        
        return selected
    }
    
    // TODO: make selection stuff an extension of list
    
    // MARK: - Atomic Selection Operations
    
    func setSelectionWithTasksListed(at newIndexes: [Int])
    {
        var newSelections = Array<Bool>(repeating: false, count: count)
        
        for selectedIndex in newIndexes
        {
            newSelections[selectedIndex] = true
        }
        
        for index in 0 ..< count
        {
            self[index]?.data?.set(isSelected: newSelections[index])
        }
        
        send(.didChangeSelection)
    }
    
    func selectTask(at index: Int)
    {
        guard let data = self[index]?.data, !data.isSelected.latestUpdate else
        {
            return
        }
        
        data.set(isSelected: true)
        
        send(.didChangeSelection)
    }
    
    func toggleSelection(at index: Int)
    {
        guard let data = self[index]?.data else { return }
        
        let itemIsSelected = data.isSelected.latestUpdate
        data.set(isSelected: !itemIsSelected)
        
        send(.didChangeSelection)
    }
    
    func deselectItems(at indexes: [Int])
    {
        for index in indexes
        {
            self[index]?.data?.set(isSelected: false)
        }
        
        send(.didChangeSelection)
    }
}

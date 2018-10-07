import SwiftObserver
import SwiftyToolz

// MARK: - Tags

extension SelectableList
{
    func set(tag: ItemData.Tag?)
    {
        let selectedTasks = selection.tasks
        
        guard !selectedTasks.isEmpty else { return }
        
        if selectedTasks.count == 1
        {
            selectedTasks[0].data?.tag <- selectedTasks[0].data?.tag.value != tag ? tag : nil
        }
        else
        {
            for selectedTask in selectedTasks
            {
                selectedTask.data?.tag <- tag
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
        if selection.count < 2
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
        guard selection.count > 1 else
        {
            log(warning: "Tried to group less than 2 selected tasks.")
            return
        }
        
        let indexes = selection.indexes
        let groupState = root?.highestPriorityState(at: indexes)
        
        if let group = root?.groupNodes(at: indexes)
        {
            selection.set(with: group)
            group.data = ItemData()
            group.data?.state <- groupState
            group.data?.send(.wantTextInput)
        }
    }
    
    func createBelowSelection()
    {
        create(at: newIndexBelowSelection)
    }
    
    func create(at index: Int)
    {
        guard let newTask = root?.createSubitem(at: index) else { return }
        
        selection.set(with: newTask)
    }
    
    // MARK: - Paste
    
    func paste(_ tasks: [Item])
    {
        let index = newIndexBelowSelection
        
        guard root?.insert(tasks, at: index) ?? false else { return }
        
        let pastedIndexes = Array(index ..< index + tasks.count)
        
        selection.setWithTasksListed(at: pastedIndexes)
    }
    
    // MARK: - Remove
    
    @discardableResult
    func removeSelectedTasks() -> Bool
    {
        let selectedIndexes = selection.indexes
        
        guard let root = root,
            let firstSelectedIndex = selectedIndexes.first,
            let removedTasks = root.removeNodes(from: selectedIndexes),
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
        
        selection.setWithTasksListed(at: [max(index - 1, 0)])
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
        return (selection.indexes.last ?? -1) + 1
    }
    
    // MARK: - Toggle States
    
    func toggleInProgressStateOfFirstSelectedTask()
    {
        guard let task = firstSelectedTask else { return }
        
        if selection.count > 1
        {
            selection.remove(tasks: [task])
        }
        
        task.data?.state <- !task.isInProgress ? .inProgress : nil
    }
    
    func toggleDoneStateOfFirstSelectedTask()
    {
        guard let selected = selection.indexes.first, let task = self[selected] else
        {
            return
        }
        
        let newSelectedTask = nextSelectedTaskAfterCheckingOff(at: selected)
        
        let newState: ItemData.State? = !task.isDone ? .done : nil
        
        if selection.count == 1, newState == .done, let newSelectedTask = newSelectedTask
        {
            selection.set(with: newSelectedTask)
        }
        else if selection.count > 1
        {
            selection.remove(tasks: [task])
        }
        
        task.data?.state <- newState
    }
    
    private func nextSelectedTaskAfterCheckingOff(at index: Int) -> Item?
    {
        for i in index + 1 ..< numberOfTasks
        {
            guard let task = self[i] else { continue }
            
            if task.isOpen { return task }
        }
        
        for i in (0 ..< index).reversed()
        {
            guard let task = self[i] else { continue }
            
            if task.isOpen { return task }
        }
        
        return nil
    }
    
    // MARK: - Move
    
    func canMoveItems(up: Bool) -> Bool
    {
        guard selection.count == 1, let selected = selection.indexes.first else
        {
            return false
        }
        
        if up && selected == 0 { return false }
        
        if !up && selected == numberOfTasks - 1 { return false }
        
        return true
    }
    
    @discardableResult
    func moveSelectedTask(_ positions: Int) -> Bool
    {
        guard positions != 0,
            let root = root,
            selection.count == 1,
            let selectedTask = selection.someTask,
            let selectedIndex = root.index(of: selectedTask)
        else
        {
            return false
        }
        
        return root.moveNode(from: selectedIndex,
                                to: selectedIndex + positions)
    }
    
    // MARK: - Edit Title
    
    func editTitle()
    {
        guard let index = selection.indexes.first else { return }
        
        editTitle(at: index)
    }
    
    // MARK: - Manage the Selection
    
    func select()
    {
        if numberOfTasks > 0 && selection.count == 0
        {
            selection.setWithTasksListed(at: [0])
        }
    }
    
    func selectAll()
    {
        selection.setWithTasksListed(at: Array(0 ..< numberOfTasks))
    }
    
    var canShiftSelectionUp: Bool
    {
        return numberOfTasks > 0 && selection.indexes != [0]
    }
    
    func shiftSelectionUp()
    {
        if let firstIndex = selection.indexes.first, firstIndex > 0
        {
            selection.setWithTasksListed(at: [firstIndex - 1])
        }
        else if numberOfTasks > 0
        {
            selection.setWithTasksListed(at: [0])
        }
    }
    
    var canShiftSelectionDown: Bool
    {
        return numberOfTasks > 0 && selection.indexes != [numberOfTasks - 1]
    }
    
    func shiftSelectionDown()
    {
        if let lastIndex = selection.indexes.last, lastIndex + 1 < numberOfTasks
        {
            selection.setWithTasksListed(at: [lastIndex + 1])
            return
        }
        else if numberOfTasks > 0
        {
            selection.setWithTasksListed(at: [numberOfTasks - 1])
        }
    }
    
    var canExtendSelectionUp: Bool
    {
        guard let index = selection.indexes.first,
            index > 0 else { return false }
        
        return true
    }
    
    func extendSelectionUp()
    {
        guard let index = selection.indexes.first,
            index > 0 else { return }
        
        selection.add(task: self[index - 1])
    }
    
    var canExtendSelectionDown: Bool
    {
        guard let index = selection.indexes.last,
            index + 1 < numberOfTasks else { return false }
        
        return true
    }
    
    func extendSelectionDown()
    {
        guard let index = selection.indexes.last,
            index + 1 < numberOfTasks else { return }
        
        selection.add(task: self[index + 1])
    }
    
    var firstSelectedTask: Item?
    {
        guard let index = selection.indexes.first else { return nil }
        
        return self[index]
    }
    
    override func set(root newRoot: Item?)
    {
        super.set(root: newRoot)
        
        selection.root = newRoot
    }
    
    override func received(_ edit: Item.Edit,
                           from root: Item)
    {
        super.received(edit, from: root)
        
        if case .remove(let subtasks, _) = edit
        {
            selection.remove(tasks: subtasks)
        }
    }
    
    let selection = Selection()
}

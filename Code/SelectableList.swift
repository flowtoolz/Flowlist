import SwiftObserver
import SwiftyToolz

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
        
        if let group = root?.groupSubtasks(at: selection.indexes)
        {
            selection.set(with: group)
        }
    }
    
    func createBelowSelection()
    {
        create(at: newIndexBelowSelection)
    }
    
    func create(at index: Int)
    {
        guard let newTask = root?.create(at: index) else { return }
        
        selection.set(with: newTask)
    }
    
    // MARK: - Remove
    
    @discardableResult
    func removeSelectedTasks() -> Bool
    {
        let selectedIndexes = selection.indexes
        
        guard let root = root,
            let firstSelectedIndex = selectedIndexes.first,
            let removedTasks = root.removeSubtasks(at: selectedIndexes),
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
        guard root?.hasBranches ?? false else { return }
        
        selection.setWithTasksListed(at: [max(index - 1, 0)])
    }
    
    func undoLastRemoval()
    {
        let index = newIndexBelowSelection
        
        guard let recovered = root?.insertLastRemoved(at: index),
            recovered > 0 else { return }
        
        let recoveredIndexes = Array(index ..< index + recovered)
        
        selection.setWithTasksListed(at: recoveredIndexes)
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
        
        task.state <- !task.isInProgress ? .inProgress : nil
    }
    
    func toggleDoneStateOfFirstSelectedTask()
    {
        guard let selected = selection.indexes.first, let task = self[selected] else
        {
            return
        }
        
        let newSelectedTask = nextSelectedTaskAfterCheckingOff(at: selected)
        
        let newState: TaskState? = !task.isDone ? .done : nil
        
        if selection.count == 1, newState == .done, let newSelectedTask = newSelectedTask
        {
            selection.set(with: newSelectedTask)
        }
        else if selection.count > 1
        {
            selection.remove(tasks: [task])
        }
        
        task.state <- newState
    }
    
    private func nextSelectedTaskAfterCheckingOff(at index: Int) -> Task?
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
        
        return root.moveSubtask(from: selectedIndex,
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
        guard let index = selection.indexes.first else { return }
        
        if index > 0
        {
            selection.setWithTasksListed(at: [index - 1])
        }
        else if numberOfTasks > 0 && selection.count != 1
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
        guard let index = selection.indexes.last else { return }
        
        if index + 1 < numberOfTasks
        {
            selection.setWithTasksListed(at: [index + 1])
        }
        else if numberOfTasks > 0 && selection.count != 1
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
    
    var firstSelectedTask: Task?
    {
        guard let index = selection.indexes.first else { return nil }
        
        return self[index]
    }
    
    override func set(root newRoot: Task?)
    {
        super.set(root: newRoot)
        
        selection.root = newRoot
    }
    
    override func received(_ edit: Edit, from root: Task)
    {
        super.received(edit, from: root)
        
        if case .remove(let subtasks, _) = edit
        {
            selection.remove(tasks: subtasks)
        }
    }
    
    let selection = Selection()
}

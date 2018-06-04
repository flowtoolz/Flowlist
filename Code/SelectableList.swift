import SwiftObserver
import SwiftyToolz

class SelectableList: List
{
    // MARK: - Selection Dependent Editing
    
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
    
    var newIndexBelowSelection: Int
    {
        return (selection.indexes.last ?? -1) + 1
    }
    
    func create(at index: Int)
    {
        guard let newTask = root?.create(at: index) else { return }
        
        selection.set(with: newTask)
    }
    
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
    
    func undoLastRemoval()
    {
        let index = newIndexBelowSelection
        
        guard let recovered = root?.insertLastRemoved(at: index),
            recovered > 0 else { return }
        
        let recoveredIndexes = Array(index ..< index + recovered)
        
        selection.setWithTasksListed(at: recoveredIndexes)
    }
    
    func selectAfterRemoval(from index: Int)
    {
        guard root?.hasBranches ?? false else { return }
        
        selection.setWithTasksListed(at: [max(index - 1, 0)])
    }
    
    @discardableResult
    func moveSelectedTask(_ positions: Int) -> Bool
    {
        guard positions != 0,
            let root = root,
            selection.count == 1,
            let selectedTask = selection.first,
            let selectedIndex = root.index(of: selectedTask)
        else
        {
            return false
        }

        return root.moveSubtask(from: selectedIndex,
                                to: selectedIndex + positions)
    }
    
    func checkOffFirstSelectedUncheckedTask()
    {
        guard let task = firstSelectedUnchecked() else { return }
        
        task.state <- .done
        
        guard let nextIndex = root?.indexOfFirstUncheckedSubtask() else { return }
        
        if selection.count == 1
        {
            selection.setWithTasksListed(at: [nextIndex])
        }
        else if selection.count > 1
        {
            selection.remove(tasks: [task])
        }
    }
    
    private func firstSelectedUnchecked() -> Task?
    {
        for selectedIndex in selection.indexes
        {
            if let task = self[selectedIndex], !task.isDone
            {
                return task
            }
        }
        
        return nil
    }
    
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
    
    override func set(root newRoot: Task?)
    {
        super.set(root: newRoot)
        
        selection.root = newRoot
    }
    
    override func received(_ edit: Edit, from root: Task)
    {
        super.received(edit, from: root)
        
        if case .didRemove(let subtasks, _) = edit
        {
            selection.remove(tasks: subtasks)
        }
    }
    
    let selection = Selection()
}

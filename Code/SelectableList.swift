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
        create(at: (selection.indexes.last ?? -1) + 1)
    }
    
    // FIXME: move to List, than override here
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
            root.removeSubtasks(at: selectedIndexes).count > 0
        else
        {
            return false
        }
       
        guard root.hasBranches else { return true }
        
        let newSelectedIndex = max(firstSelectedIndex - 1, 0)
        
        selection.setWithTasksListed(at: [newSelectedIndex])
        
        return true
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
            if let task = task(at: selectedIndex), !task.isDone
            {
                return task
            }
        }
        
        return nil
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
    
    override func received(_ edit: ListEdit, from root: Task)
    {
        super.received(edit, from: root)
        
        if case .didRemove(let subtasks, _) = edit
        {
            selection.remove(tasks: subtasks)
        }
    }
    
    let selection = Selection()
}

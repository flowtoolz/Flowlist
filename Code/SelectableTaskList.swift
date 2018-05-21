import SwiftObserver
import SwiftyToolz

class SelectableTaskList: TaskList
{
    // MARK: - Selection Dependent Editing
    
    func groupSelectedTasks() -> Int?
    {
        let group = root?.groupSubtasks(at: selection.indexes)
        
        selection.add(task: group)
        
        return group?.indexInSupertask
    }
    
    func insertBelowSelection(_ task: Task) -> Int?
    {
        let index = (selection.indexes.last ?? -1) + 1
        
        return insert(task, at: index)
    }
    
    func insert(_ task: Task, at index: Int) -> Int?
    {
        guard task === root?.insert(task, at: index) else { return nil }
        
        selection.setWithTasksListed(at: [index])
        
        return index
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
       
        let newSelectedIndex = max(firstSelectedIndex - 1, 0)
        
        selection.setWithTasksListed(at: [newSelectedIndex])
        
        return true
    }
    
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
    
    let selection = TaskSelection()
}

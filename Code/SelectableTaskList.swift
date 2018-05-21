import SwiftObserver
import SwiftyToolz

class SelectableTaskList: TaskList
{
    // MARK: - Selection Dependent Editing
    
    func groupSelectedTasks() -> Int?
    {
        let group = supertask?.groupSubtasks(at: selection.indexes)
        
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
        guard task === supertask?.insert(task, at: index) else { return nil }
        
        selection.setWithTasksListed(at: [index])
        
        return index
    }
    
    func removeSelectedTasks() -> Bool
    {
        // delete
        let selectedIndexes = selection.indexes
        
        guard let firstSelectedIndex = selectedIndexes.first,
            let removedTasks = supertask?.removeSubtasks(at: selectedIndexes),
            !removedTasks.isEmpty
        else
        {
            return false
        }
        
        // update selection
        if let newSelectedTask = task(at: max(firstSelectedIndex - 1, 0))
        {
            selection.add(task: newSelectedTask)
        }
        else
        {
            selection.removeAll()
        }
        
        return true
    }
    
    func moveSelectedTask(_ positions: Int) -> Bool
    {
        guard positions != 0,
            let supertask = supertask,
            selection.count == 1,
            let selectedTask = selection.first,
            let selectedIndex = supertask.index(of: selectedTask)
        else
        {
            return false
        }

        return supertask.moveSubtask(from: selectedIndex,
                                     to: selectedIndex + positions)
    }
    
    func checkOffFirstSelectedUncheckedTask()
    {
        guard let (index, task) = firstSelectedUnchecked() else
        {
            return
        }
        
        // determine which task to select after the ckeck off
        var taskToSelect: Task?
        
        if selection.count == 1
        {
            let unchecked = supertask?.indexOfFirstUncheckedSubtask(from: index + 1)
            
            taskToSelect = supertask?.subtask(at: unchecked)
        }
        
        task.state <- .done
        
        if let taskToSelect = taskToSelect
        {
            selection.add(task: taskToSelect)
        }
        else if selection.count > 1
        {
            selection.remove(tasks: [task])
        }
    }
    
    private func firstSelectedUnchecked() -> (Int, Task)?
    {
        for selectedIndex in selection.indexes
        {
            if let task = task(at: selectedIndex), !task.isDone
            {
                return (selectedIndex, task)
            }
        }
        
        return nil
    }
    
    // MARK: - Manage the Selection
    
    override func set(supertask newSupertask: Task?)
    {
        super.set(supertask: newSupertask)
        
        selection.supertask = newSupertask
    }
    
    override func received(_ edit: ListEdit, from supertask: Task)
    {
        super.received(edit, from: supertask)
        
        switch edit
        {
        case .didRemove(let subtasks, _): selection.remove(tasks: subtasks)
            
        default: break
        }
    }
    
    let selection = TaskSelection()
}

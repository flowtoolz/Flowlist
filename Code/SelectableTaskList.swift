import SwiftObserver
import SwiftyToolz

extension SelectableTaskList
{
    func debug()
    {
        print("════════════════════════════════════════════════\n\n" + description + "\n")
    }
    
    var description: String
    {
        var desc = title.latestUpdate + ":"
        
        for i in 0 ..< numberOfTasks
        {
            guard let task = task(at: i) else { continue }
            
            desc += "\n- \(task.title.value ?? "untitled")"
        }
        
        return desc
    }
}

class SelectableTaskList: TaskList
{
    // MARK: - Selection Dependent Editing
    
    func groupSelectedTasks() -> Int?
    {
        let group = supertask?.groupSubtasks(at: selection.indexes)
        
        selection.add(group)
        
        return group?.indexInSupertask
    }
    
    func insertBelowSelection(_ task: Task) -> Int?
    {
        let index = (selection.indexes.last ?? -1) + 1
        
        return supertask?.insert(task, at: index) != nil ? index : nil
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
            selection.add(newSelectedTask)
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
            selection.add(taskToSelect)
        }
        else if selection.count > 1
        {
            selection.remove(task)
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
        selection.supertask = newSupertask
        
        super.set(supertask: newSupertask)
    }
    
    override func received(_ change: Task.SubtaskChange, from supertask: Task)
    {
        switch change
        {
        case .didRemove(let subtasks, _): selection.remove(subtasks)
            
        default: return
        }
        
        super.received(change, from: supertask)
    }
    
    let selection = TaskSelection()
}

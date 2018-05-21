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
        let selectedIndexes = selection.indexes
        
        guard let supertask = supertask,
            let firstSelectedIndex = selectedIndexes.first,
            supertask.removeSubtasks(at: selectedIndexes).count > 0
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
        guard let task = firstSelectedUnchecked() else { return }
        
        task.state <- .done
        
        guard let nextIndex = supertask?.indexOfFirstUncheckedSubtask() else { return }
        
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
    
    override func set(supertask newSupertask: Task?)
    {
        super.set(supertask: newSupertask)
        
        selection.supertask = newSupertask
    }
    
    override func received(_ edit: ListEdit, from supertask: Task)
    {
        super.received(edit, from: supertask)
        
        if case .didRemove(let subtasks, _) = edit
        {
            selection.remove(tasks: subtasks)
        }
    }
    
    let selection = TaskSelection()
}

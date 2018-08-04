import SwiftyToolz

extension Task
{
    func cut(at indexes: [Int]) -> Bool
    {
        guard copy(at: indexes) else { return false }
        
        removeSubtasks(at: indexes)
        
        return true
    }
    
    @discardableResult
    func copy(at indexes: [Int]) -> Bool
    {
        let tasks = self[indexes]
        
        guard !tasks.isEmpty else { return false }
        
        clipboard.storeCopies(of: tasks)
        
        return true
    }
    
    var clipboardTasks: [Task]
    {
        return clipboard.copiesOfStoredObjects
    }
}

let clipboard = Clipboard<Task>()

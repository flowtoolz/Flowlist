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
    
    func paste(at index: Int) -> Int?
    {
        let copies = clipboard.copiesOfStoredObjects
        
        guard insert(copies, at: index) else { return nil }
        
        return copies.count
    }
}

let clipboard = Clipboard<Task>()

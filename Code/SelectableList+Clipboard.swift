extension SelectableList
{
    func cut()
    {
        let selectedIndexes = selection.indexes
        
        guard let firstSelectedIndex = selectedIndexes.first,
            root?.cut(at: selectedIndexes) ?? false else { return }
        
        selectAfterRemoval(from: firstSelectedIndex)
    }
    
    func copy()
    {
        guard let root = root else { return }
        
        let indexes = selection.indexes
        
        var tasks = [Task]()
        
        for index in indexes
        {
            guard let task = root[index] else { continue }
            
            tasks.append(task)
        }
        
        root.copy(tasks)
    }
    
    func pasteFromClipboard()
    {
        guard let tasks = root?.clipboardTasks, !tasks.isEmpty else
        {
            return
        }
        
        paste(tasks)
    }
}

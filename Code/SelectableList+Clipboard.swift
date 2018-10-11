extension SelectableList
{
    func cut()
    {
        let selected = selectedIndexes
        
        guard let firstSelectedIndex = selected.first,
            root?.cut(at: selected) ?? false else { return }
        
        selectAfterRemoval(from: firstSelectedIndex)
    }
    
    func copy()
    {
        guard let root = root else { return }
        
        let indexes = selectedIndexes
        
        var tasks = [Item]()
        
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

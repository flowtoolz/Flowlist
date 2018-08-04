extension SelectableList
{
    func cut()
    {
        let selectedIndexes = selection.indexes
        
        guard let firstSelectedIndex = selectedIndexes.first,
            root?.cut(at: selectedIndexes) ?? false else { return }
        
        selectAfterRemoval(from: firstSelectedIndex)
    }
    
    func copy() { root?.copy(at: selection.indexes) }
    
    func pasteFromClipboard()
    {
        guard let tasks = root?.clipboardTasks, !tasks.isEmpty else
        {
            return
        }
        
        paste(tasks)
    }
}

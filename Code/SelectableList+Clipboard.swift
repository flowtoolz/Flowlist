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
    
    func paste()
    {
        let index = newIndexBelowSelection
        
        guard let pasted = root?.paste(at: index), pasted > 0 else { return }
        
        let pastedIndexes = Array(index ..< index + pasted)
        
        selection.setWithTasksListed(at: pastedIndexes)
    }
}

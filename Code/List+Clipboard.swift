extension List
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
        
        var items = [ItemDataTree]()
        
        for index in indexes
        {
            guard let item = root[index] else { continue }
            
            items.append(item)
        }
        
        root.copy(items)
    }
    
    func pasteFromClipboard()
    {
        guard let items = root?.clipboardItems, !items.isEmpty else
        {
            return
        }
        
        paste(items)
    }
}

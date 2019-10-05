extension List
{
    func select()
    {
        if count > 0 && selectedIndexes.count == 0
        {
            setSelectionWithItemsListed(at: [0])
        }
    }
    
    func selectAll()
    {
        setSelectionWithItemsListed(at: Array(0 ..< count))
    }
    
    var canShiftSelectionUp: Bool
    {
        count > 0 && selectedIndexes != [0]
    }
    
    func shiftSelectionUp()
    {
        if let firstIndex = selectedIndexes.first, firstIndex > 0
        {
            setSelectionWithItemsListed(at: [firstIndex - 1])
        }
        else if count > 0
        {
            setSelectionWithItemsListed(at: [0])
        }
    }
    
    var canShiftSelectionDown: Bool
    {
        count > 0 && selectedIndexes != [count - 1]
    }
    
    func shiftSelectionDown()
    {
        if let lastIndex = selectedIndexes.last, lastIndex + 1 < count
        {
            setSelectionWithItemsListed(at: [lastIndex + 1])
            return
        }
        else if count > 0
        {
            setSelectionWithItemsListed(at: [count - 1])
        }
    }
    
    var canExtendSelectionUp: Bool
    {
        guard let index = selectedIndexes.first, index > 0 else
        {
            return false
        }
        
        return true
    }
    
    func extendSelectionUp()
    {
        guard let index = selectedIndexes.first, index > 0 else
        {
            return
        }
        
        selectItem(at: index - 1)
    }
    
    var canExtendSelectionDown: Bool
    {
        guard let index = selectedIndexes.last, index + 1 < count else
        {
            return false
        }
        
        return true
    }
    
    func extendSelectionDown()
    {
        guard let index = selectedIndexes.last, index + 1 < count else
        {
            return
        }
        
        selectItem(at: index + 1)
    }
    
    func extendSelection(to index: Int)
    {
        guard root?.children.isValid(index: index) ?? false else { return }
        
        let selected = selectedIndexes
        
        guard !selected.isEmpty,
            let first = selected.first,
            let last = selected.last else { return }
        
        if index < first
        {
            selectItems(at: Array(index ... first - 1))
        }
        else if index > last
        {
            selectItems(at: Array(last + 1 ... index))
        }
    }
    
    var selectedIndexes: [Int]
    {
        guard let items = root?.children else { return [] }
        
        return items.indices.compactMap { items[$0].isSelected ? $0 : nil }
    }
}

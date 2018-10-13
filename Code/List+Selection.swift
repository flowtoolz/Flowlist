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
        return count > 0 && selectedIndexes != [0]
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
        return count > 0 && selectedIndexes != [count - 1]
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
    
    var selectedIndexes: [Int]
    {
        var selected = [Int]()
        
        for index in 0 ..< count
        {
            if self[index]?.data?.isSelected.latestUpdate ?? false
            {
                selected.append(index)
            }
        }
        
        return selected
    }
}

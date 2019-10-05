extension Tree where Data == ItemData
{
    func moveSubitemToTopOfDoneList(from index: Int)
    {
        guard let unchecked = indexOfLastOpenSubitem else { return }
        
        let belowUnchecked = unchecked + (unchecked < index ? 1 : 0)
        
        moveChild(from: index, to: belowUnchecked)
    }
    
    var indexOfLastOpenSubitem: Int?
    {
        for subitemIndex in (0 ..< count).reversed()
        {
            if let subitem = self[subitemIndex], subitem.isOpen
            {
                return subitemIndex
            }
        }
        
        return nil
    }
    
    func moveSubitemToTopOfUndoneList(from index: Int)
    {
        let lastInProgress = indexOfLastSubitemInProgress
        
        let belowInProgress = lastInProgress + (lastInProgress < index ? 1 : 0)
        
        moveChild(from: index, to: belowInProgress)
    }
    
    var indexOfLastSubitemInProgress: Int
    {
        for subitemIndex in (0 ..< count).reversed()
        {
            if let subitem = self[subitemIndex], subitem.isInProgress
            {
                return subitemIndex
            }
        }
        
        return -1
    }
        
    func highestPriorityState(at indexes: [Int]) -> ItemData.State?
    {
        var highestPriorityState: ItemData.State? = .trashed
        
        for index in indexes
        {
            guard let subitem = self[index] else { continue }
            
            let subitemState = subitem.data.state.value
            let subitemPriority = ItemData.State.priority(of: subitemState)
            let highestPriority = ItemData.State.priority(of: highestPriorityState)
            
            if subitemPriority < highestPriority
            {
                highestPriorityState = subitemState
            }
        }
        
        return highestPriorityState
    }
    
    var isDone: Bool { data.state.value == .done }
    var isOpen: Bool { isInProgress || isUndone }
    var isInProgress: Bool { data.state.value == .inProgress }
    var isUndone: Bool { data.state.value == nil }
}

extension Tree where Data == ItemData
{
    func moveSubtaskToTopOfDoneList(from index: Int)
    {
        guard let unchecked = indexOfLastOpenSubtask else { return }
        
        let belowUnchecked = unchecked + (unchecked < index ? 1 : 0)
        
        moveNode(from: index, to: belowUnchecked)
    }
    
    var indexOfLastOpenSubtask: Int?
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
    
    func moveSubtaskToTopOfUndoneList(from index: Int)
    {
        let lastInProgress = indexOfLastSubtaskInProgress
        
        let belowInProgress = lastInProgress + (lastInProgress < index ? 1 : 0)
        
        moveNode(from: index, to: belowInProgress)
    }
    
    var indexOfLastSubtaskInProgress: Int
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
    
    func indexOfFirstOpenSubtask(from: Int = 0) -> Int?
    {
        for i in from ..< count
        {
            if let subitem = self[i], subitem.isOpen
            {
                return i
            }
        }
        
        return nil
    }
    
    func highestPriorityState(at indexes: [Int]) -> ItemData.State?
    {
        var highestPriorityState: ItemData.State? = .trashed
        
        for index in indexes
        {
            guard let subitem = self[index] else { continue }
            
            let subitemState = subitem.data?.state.value
            let subitemPriority = ItemData.State.priority(of: subitemState)
            let highestPriority = ItemData.State.priority(of: highestPriorityState)
            
            if subitemPriority < highestPriority
            {
                highestPriorityState = subitemState
            }
        }
        
        return highestPriorityState
    }
    
    var isDone: Bool { return data?.state.value == .done }
    var isOpen: Bool { return isInProgress || isUndone }
    var isInProgress: Bool { return data?.state.value == .inProgress }
    var isUndone: Bool { return data?.state.value == nil }
}

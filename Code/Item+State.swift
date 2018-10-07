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
        for subtaskIndex in (0 ..< count).reversed()
        {
            if let subtask = self[subtaskIndex], subtask.isOpen
            {
                return subtaskIndex
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
        for subtaskIndex in (0 ..< count).reversed()
        {
            if let subtask = self[subtaskIndex], subtask.isInProgress
            {
                return subtaskIndex
            }
        }
        
        return -1
    }
    
    func indexOfFirstOpenSubtask(from: Int = 0) -> Int?
    {
        for i in from ..< count
        {
            if let subtask = self[i], subtask.isOpen
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
            guard let subtask = self[index] else { continue }
            
            let subtaskState = subtask.data?.state.value
            let subtaskPriority = ItemData.State.priority(of: subtaskState)
            let highestPriority = ItemData.State.priority(of: highestPriorityState)
            
            if subtaskPriority < highestPriority
            {
                highestPriorityState = subtaskState
            }
        }
        
        return highestPriorityState
    }
    
    var isDone: Bool { return data?.state.value == .done }
    var isOpen: Bool { return isInProgress || isUndone }
    var isInProgress: Bool { return data?.state.value == .inProgress }
    var isUndone: Bool { return data?.state.value == nil }
}

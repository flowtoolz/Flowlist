extension Task
{
    func moveSubtaskToTopOfDoneList(from index: Int)
    {
        guard let unchecked = indexOfLastOpenSubtask else { return }
        
        let belowUnchecked = unchecked + (unchecked < index ? 1 : 0)
        
        moveSubtask(from: index, to: belowUnchecked)
    }
    
    var indexOfLastOpenSubtask: Int?
    {
        for subtaskIndex in (0 ..< numberOfBranches).reversed()
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
        
        moveSubtask(from: index, to: belowInProgress)
    }
    
    var indexOfLastSubtaskInProgress: Int
    {
        for subtaskIndex in (0 ..< numberOfBranches).reversed()
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
        for i in from ..< numberOfBranches
        {
            if let subtask = self[i], subtask.isOpen
            {
                return i
            }
        }
        
        return nil
    }
    
    var isDone: Bool { return data?.state.value == .done }
    var isOpen: Bool { return isInProgress || isUndone }
    var isInProgress: Bool { return data?.state.value == .inProgress }
    var isUndone: Bool { return data?.state.value == nil }
}

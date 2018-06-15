extension Task
{
    func moveSubtaskToTopOfDoneList(from index: Int)
    {
        guard let unchecked = indexOfLastUncheckedSubtask else { return }
        
        let belowUnchecked = unchecked + (unchecked < index ? 1 : 0)
        
        moveSubtask(from: index, to: belowUnchecked)
    }
    
    var indexOfLastUncheckedSubtask: Int?
    {
        for subtaskIndex in (0 ..< numberOfBranches).reversed()
        {
            if let subtask = self[subtaskIndex], !subtask.isDone
            {
                return subtaskIndex
            }
        }
        
        return nil
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
    
    var isOpen: Bool { return isInProgress || state.value == nil }
    var isDone: Bool { return state.value == .done }
    var isInProgress: Bool { return state.value == .inProgress }
}

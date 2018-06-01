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
            if let subtask = branch(at: subtaskIndex), !subtask.isDone
            {
                return subtaskIndex
            }
        }
        
        return nil
    }
    
    func indexOfFirstUncheckedSubtask(from: Int = 0) -> Int?
    {
        for i in from ..< numberOfBranches
        {
            if let subtask = branch(at: i), !subtask.isDone
            {
                return i
            }
        }
        
        return nil
    }
    
    var isDone: Bool { return state.value == .done }
}

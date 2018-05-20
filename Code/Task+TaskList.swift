extension Task
{
    func moveSubtaskToTopOfDoneList(from index: Int)
    {
        guard let unchecked = indexOfLastUncheckedSubtask else
        {
            return
        }
        
        let belowUnchecked = unchecked + (unchecked < index ? 1 : 0)
        
        moveSubtask(from: index, to: belowUnchecked)
    }
    
    var indexOfLastUncheckedSubtask: Int?
    {
        for subtaskIndex in (0 ..< numberOfSubtasks).reversed()
        {
            if let subtask = subtask(at: subtaskIndex), !subtask.isDone
            {
                return subtaskIndex
            }
        }
        
        return nil
    }
    
    func indexOfFirstUncheckedSubtask(from: Int = 0) -> Int?
    {
        for i in from ..< numberOfSubtasks
        {
            if let subtask = subtask(at: i), !subtask.isDone
            {
                return i
            }
        }
        
        return nil
    }
}

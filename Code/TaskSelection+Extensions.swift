import SwiftyToolz

extension TaskSelection
{
    var indexes: [Int]
    {
        guard let supertask = supertask else
        {
            log(warning: "Tried to get indexes from selection without supertask.")
            return []
        }
        
        var result = [Int]()
        
        for index in 0 ..< supertask.numberOfSubtasks
        {
            if let task = supertask.subtask(at: index), isSelected(task)
            {
                result.append(index)
            }
        }
        
        return result
    }
}

import SwiftyToolz

extension TaskSelection
{
    var indexes: [Int]
    {
        guard let root = root else
        {
            log(warning: "Tried to get indexes from selection without root.")
            return []
        }
        
        var result = [Int]()
        
        for index in 0 ..< root.numberOfSubtasks
        {
            if let task = root.subtask(at: index), isSelected(task)
            {
                result.append(index)
            }
        }
        
        return result
    }
}

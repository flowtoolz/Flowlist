import SwiftyToolz

extension Selection
{
    var indexes: [Int]
    {
        var result = [Int]()
        
        for index in 0 ..< (root?.numberOfSubtasks ?? 0)
        {
            if let task = root?.subtask(at: index), isSelected(task)
            {
                result.append(index)
            }
        }
        
        return result
    }
}

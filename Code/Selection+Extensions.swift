import SwiftyToolz

extension Selection
{
    var indexes: [Int]
    {
        var result = [Int]()
        
        for index in 0 ..< (root?.numberOfBranches ?? 0)
        {
            if let task = root?.branch(at: index), isSelected(task)
            {
                result.append(index)
            }
        }
        
        return result
    }
}

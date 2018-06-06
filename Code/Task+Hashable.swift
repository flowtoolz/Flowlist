import SwiftyToolz

extension Task: Hashable
{
    var hashValue: HashValue { return SwiftyToolz.hashValue(self) }
    
    static func == (lhs: Task, rhs: Task) -> Bool
    {
        return lhs === rhs
    }
}

import SwiftyToolz

extension Task: Hashable
{
    var hashValue: HashValue { return hash(self) }
    
    static func == (lhs: Task, rhs: Task) -> Bool
    {
        return lhs === rhs
    }
}

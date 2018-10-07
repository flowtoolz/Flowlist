import SwiftyToolz

extension Tree: Hashable
{
    var hashValue: HashValue { return SwiftyToolz.hashValue(self) }
    
    static func == (lhs: Tree, rhs: Tree) -> Bool
    {
        return lhs === rhs
    }
}

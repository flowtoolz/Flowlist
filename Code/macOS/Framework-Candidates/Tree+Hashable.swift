import SwiftyToolz

extension Tree: Hashable
{
    func hash(into hasher: inout Hasher)
    {
        hasher.combine(ObjectIdentifier(self))
    }
    
    static func == (lhs: Tree, rhs: Tree) -> Bool
    {
        lhs === rhs
    }
}

import SwiftObserver
import SwiftyToolz

extension ItemData: Equatable
{
    static func == (lhs: ItemData, rhs: ItemData) -> Bool
    {
        if lhs.text != rhs.text { return false }
        if lhs.state != rhs.state { return false }
        if lhs.tag != rhs.tag { return false }
        
        return true
    }
}

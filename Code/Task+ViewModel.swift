import SwiftyToolz

extension Task
{
    var backgroundColor: Color
    {
        if root == nil { return .white }
        
        guard let state = state.value else { return .backlog }
        
        switch state
        {
        case .done, .trashed: return .done
        case .inProgress: return .white
        }
    }
}

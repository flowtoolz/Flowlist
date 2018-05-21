enum ListEdit
{
    case didNothing
    case didMove(from: Int, to: Int)
    case didInsert(at: [Int])
    case didRemove(subtasks: [Task], from: [Int])
    
    var itemsDidChange: Bool
    {
        switch self
        {
        case .didRemove, .didInsert: return true
        default: return false
        }
    }
}

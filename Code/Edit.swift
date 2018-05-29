enum Edit
{
    case didNothing
    case didCreate(at: Int)
    case didInsert(at: [Int])
    case didMove(from: Int, to: Int)
    case didRemove(subtasks: [Task], from: [Int])
    
    var itemsDidChange: Bool
    {
        switch self
        {
        case .didRemove, .didInsert, .didCreate: return true
        default: return false
        }
    }
}

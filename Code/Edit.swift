enum Edit
{
    case didNothing
    case didChangeRoot(from: Task?, to: Task?)
    case didCreate(at: Int)
    case didInsert(at: [Int])
    case didMove(from: Int, to: Int)
    case didRemove(subtasks: [Task], from: [Int])
    
    var itemsDidChange: Bool
    {
        switch self
        {
        case .didRemove, .didInsert, .didCreate, .didChangeRoot: return true
        default: return false
        }
    }
}

enum Edit
{
    case nothing
    case changeRoot(from: Task?, to: Task?)
    case create(at: Int)
    case insert(at: [Int])
    case move(from: Int, to: Int)
    case remove(subtasks: [Task], from: [Int])
    
    var changesItems: Bool
    {
        switch self
        {
        case .remove, .insert, .create, .changeRoot: return true
        default: return false
        }
    }
}

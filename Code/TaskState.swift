enum TaskState: Int, Codable
{
    case inProgress = 0, done = 2, trashed = 3
    
    // FIXME: make "undone" an explicit state (raw value 1) instead of using nil for it. then remove this function and just use rawValue
    
    static func priority(of state: TaskState?) -> Int
    {
        return state?.rawValue ?? 1
    }
}

enum TaskState: Int, Codable
{
    // FIXME: make "undone" an explicit state instead of using nil for it. then remove this function and just use rawValue
    
    case inProgress, done = 2, trashed = 3
    
    static func priority(of state: TaskState?) -> Int
    {
        guard let state = state else { return 1 }
        
        if state == .inProgress { return 0 }
        
        return state.rawValue + 1
    }
}

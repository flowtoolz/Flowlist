enum TaskState: Int, Codable
{
    case inProgress, done, trashed
    
    // FIXME: make "undone" an explicit state instead of using nil for it. then remove this function and just use rawValue
    static func priority(of state: TaskState?) -> Int
    {
        guard let state = state else { return 1 }
        
        if state == .inProgress { return 0 }
        
        return state.rawValue + 1
    }
}

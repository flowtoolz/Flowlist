enum TaskState: Int, Codable
{
    case inProgress = 0, done = 2, trashed = 3 // do not change this! it's how the user's json gets decoded.
    
    static func priority(of state: TaskState?) -> Int
    {
        return state?.rawValue ?? 1
    }
}

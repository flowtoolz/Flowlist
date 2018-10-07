import SwiftObserver

final class ItemData
{
    var title = Var<String>()
    var state = Var<State>()
    var tag = Var<Tag>()
    
    enum Tag: Int, Codable
    {
        case red, orange, yellow, green, blue, purple
        
        var string: String
        {
            switch self
            {
            case .red: return "Red"
            case .orange: return "Orange"
            case .yellow: return "Yellow"
            case .green: return "Green"
            case .blue: return "Blue"
            case .purple: return "Purple"
            }
        }
    }
    
    enum State: Int, Codable
    {
        case inProgress = 0, done = 2, trashed = 3 // do not change this! it's how the user's json gets decoded.
        
        static func priority(of state: State?) -> Int
        {
            return state?.rawValue ?? 1
        }
    }
}

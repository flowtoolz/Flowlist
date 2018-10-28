import SwiftObserver
import SwiftyToolz

final class ItemData: Observable
{
    // MARK: - Initialization
    
    init(id: String? = nil)
    {
        self.id = id ?? String.uuid
    }
    
    // MARK: - View Model
    
    let isSelected = Var(false)
    let isFocused = Var(true)
    
    // MARK: - Text
    
    var text = Var<String>()
    
    func edit() { send(.wantTextInput) }
    
    var wantsTextInput = false
    
    // MARK: - State
    
    var state = Var<State>()
    
    enum State: Int, Codable
    {
        // do not change this!
        case inProgress = 0, done = 2, trashed = 3
        
        static func priority(of state: State?) -> Int
        {
            return state?.rawValue ?? 1
        }
    }
    
    // MARK: - Tag
    
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
    
    // MARK: - Observability
    
    var latestUpdate = Event.nothing
    
    enum Event { case nothing, wantTextInput }
    
    // MARK: - ID
    
    let id: String
}

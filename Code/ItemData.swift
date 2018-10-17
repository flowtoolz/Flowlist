import SwiftObserver

final class ItemData: Observable
{
    // MARK: - Selection
    
    lazy var isSelected = isSelectedVar.new().filter({ $0 != nil }).unwrap(false)
    
    func set(isSelected: Bool)
    {
        isSelectedVar <- isSelected
    }
    
    private let isSelectedVar = Var(false)
    
    // MARK: - Focus
    
    lazy var isFocused = isFocusedVar.new().filter({ $0 != nil }).unwrap(false)
    
    func set(isFocused: Bool)
    {
        isFocusedVar <- isFocused
    }
    
    private let isFocusedVar = Var(true)
    
    // MARK: - Title
    
    var title = Var<String>()
    
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
}

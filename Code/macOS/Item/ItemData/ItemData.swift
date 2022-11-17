import SwiftObserver
import SwiftyToolz

final class ItemData: Observer, Observable
{
    // MARK: - Life Cycle
    
    init(id: ID? = nil, wantsTextInput: Bool = false)
    {
        self.id = id ?? .randomID()
        self.wantsTextInput = wantsTextInput
        
        observe(text)
        {
            [weak self] textChange in
            
            if textChange.old != textChange.new
            {
                self?.wantsTextInput = false
            }
            
            self?.send(.wasModified)
        }
        
        observe(state)
        {
            [weak self] _ in self?.send(.wasModified)
        }
        
        observe(tag)
        {
            [weak self] _ in self?.send(.wasModified)
        }
    }
    
    // MARK: - View Model
    
    let isSelected = Var(false)
    let isFocused = Var(true)
    
    // MARK: - Text
    
    let text = Var<String?>()
    
    func requestTextInput() { send(.wantTextInput) }
    func startedEditing() { wantsTextInput = false }
    
    private(set) var wantsTextInput: Bool
    
    // MARK: - State
    
    let state = Var<State?>()
    
    enum State: Int, Codable
    {
        init?(integer: Int?)
        {
            guard let int = integer, let state = State(rawValue: int) else
            {
                return nil
            }
            
            self = state
        }
        
        // do not change this!
        case inProgress = 0, done = 2, trashed = 3
        
        static func priority(of state: State?) -> Int
        {
            return state?.rawValue ?? 1
        }
    }
    
    // MARK: - Tag
    
    let tag = Var<Tag?>()
    
    enum Tag: Int, Codable
    {
        init?(integer: Int?)
        {
            guard let int = integer, let tag = Tag(rawValue: int) else
            {
                return nil
            }
            
            self = tag
        }
        
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

    // TODO: remove the concern of data observation from Tree and move it to specific ItemTree
    
    // MARK: - Observability
    
    let messenger = Messenger<Event>()
    
    enum Event: Equatable
    {
        case wasModified
        case wantTextInput
    }
    
    // MARK: - ID
    
    let id: ID
    
    typealias ID = String
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

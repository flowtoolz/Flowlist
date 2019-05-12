import SwiftObserver
import SwiftyToolz

final class ItemData: Observer, CustomObservable
{
    // MARK: - Life Cycle
    
    init(id: String? = nil)
    {
        self.id = id ?? String.makeUUID()
        
        wantsTextInput = id == nil
        
        observe(text, state, tag)
        {
            [weak self] textUpdate, _, _ in
            
            if textUpdate.old != textUpdate.new
            {
                self?.wantsTextInput = false
            }
            
            self?.send(.wasModified)
        }
    }
    
    // MARK: - View Model
    
    let isSelected = Var(false)
    let isFocused = Var(true)
    
    // MARK: - Text
    
    let text = Var<String?>()
    
    func requestTextInput() { send(.wantTextInput) }
    func startedEditing() { wantsTextInput = false }
    
    private(set) var wantsTextInput = false
    
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
        // TODO: use this everywhere where optional Ints are written to property tag... same for state...
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
    
    let messenger = Messenger(Event.didNothing)
    
    typealias Message = Event
    
    enum Event: Equatable
    {
        case didNothing
        case wasModified
        case wantTextInput
    }
    
    // MARK: - ID
    
    let id: String
}

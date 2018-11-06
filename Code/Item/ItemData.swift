import SwiftObserver
import SwiftyToolz

final class ItemData: Observable, Observer
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
    
    deinit
    {
        stopAllObserving()
        removeObservers()
    }
    
    // MARK: - View Model
    
    let isSelected = Var(false)
    let isFocused = Var(true)
    
    // MARK: - Text
    
    let text = Var<String>()
    
    func requestTextInput() { send(.wantTextInput) }
    func startedEditing() { wantsTextInput = false }
    
    private(set) var wantsTextInput = false
    
    // MARK: - State
    
    let state = Var<State>()
    
    enum State: Int, Codable
    {
        init?(from value: Int?)
        {
            guard let value = value, let state = State(rawValue: value) else
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
    
    let tag = Var<Tag>()
    
    enum Tag: Int, Codable
    {
        // TODO: use this everywhere where optional Ints are written to property tag... same for state...
        init?(from value: Int?)
        {
            guard let value = value, let tag = Tag(rawValue: value) else
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
    
    // MARK: - Observability
    
    var latestUpdate = Event.didNothing
    
    enum Event: Equatable
    {
        case didNothing
        case wasModified
        case wantTextInput
        case didTypeText(_ text: String)
    }
    
    // MARK: - ID
    
    let id: String
}
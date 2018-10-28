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
    
    // MARK: - Title
    
    var title = Var<String>()
    
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

extension String
{
    static var uuid: String
    {
        // create random bytes
        
        var bytes = [Byte]()
        
        for _ in 0 ..< 16 { bytes.append(Byte.random()) }
        
        // indicate UUID version and variant
        
        bytes[6] = (bytes[6] & 0x0f) | 0x40 // version 4
        bytes[8] = (bytes[8] & 0x3f) | 0x80 // variant 1
        
        // create string representation
        
        let ranges = [0 ..< 4, 4 ..< 6, 6 ..< 8, 8 ..< 10, 10 ..< 16]
        
        return ranges.map
        {
            range in
            
            var string = ""
            
            for i in range
            {
                string += String(bytes[i], radix: 16, uppercase: false)
            }
            
            return string
        }.joined(separator: "-")
    }
}

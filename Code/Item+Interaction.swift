import SwiftObserver

extension Tree where Data == ItemData
{
    convenience init(from modification: Modification)
    {
        let data = ItemData(id: modification.id)
        
        data.text <- modification.text
        data.state <- modification.state
        data.tag <- modification.tag
        
        self.init(data: data)
    }
    
    enum Interaction
    {
        // TODO: generalize Interaction so it can describe batch edits
        init(from event: Item.TreeEvent.RootEvent)
        {
            switch event
            {
            case .didRemove(let items):
                self = .none
                
            case .didInsert(let items,
                            in: let superItem,
                            at: let indexes):
                self = .none
            }
        }
        
        case none
        case create(_ modification: Modification)
        case modify(_ modification: Modification)
        case delete(id: String)
    }
    
    struct Modification
    {
        init(id: String,
             text: String? = nil,
             state: ItemData.State? = nil,
             tag: ItemData.Tag? = nil,
             rootId: String? = nil,
             modified: [Field] = Field.all)
        {
            self.id = id
            self.text = text
            self.state = state
            self.tag = tag
            self.rootId = rootId
            self.modified = modified
        }
        
        let id: String
        let text: String?
        let state: ItemData.State?
        let tag: ItemData.Tag?
        let rootId: String?
        let modified: [Field]
    }
    
    enum Field: String
    {
        case text, state, tag, root
        
        static let all: [Field] = [text, state, tag, root]
    }
}

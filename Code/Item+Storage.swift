import SwiftObserver

extension Tree where Data == ItemData
{
    convenience init(with edit: Edit)
    {
        let data = ItemData(id: edit.id)
        
        data.text <- edit.text
        data.state <- edit.state
        data.tag <- edit.tag
        
        self.init(data: data)
    }
    
    enum Operation
    {
        // TODO: generalize ItemEdit so it can inform about batch edits
        init(from event: Item.TreeEvent.RootEvent)
        {
            switch event
            {
            case .didRemove(let items):
                self = .didNothing
                
            case .didInsert(let items,
                            in: let superItem,
                            at: let indexes):
                self = .didNothing
            }
        }
        
        case didNothing
        case didCreate(_ edit: Edit)
        case didModify(_ edit: Edit)
        case didDelete(id: String)
    }
    
    struct Edit
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

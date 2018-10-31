import SwiftObserver

extension Tree where Data == ItemData
{
    enum Edit
    {
        // TODO: generalize ItemEdit so it can inform about batch edits
        init(from event: Item.Event.RootEvent)
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
        case didCreate(_ info: EditInfo)
        case didModify(_ info: EditInfo)
        case didDelete(id: String)
    }
    
    struct EditInfo
    {
        init(id: String,
             text: String? = nil,
             state: ItemData.State? = nil,
             tag: ItemData.Tag? = nil,
             rootId: String? = nil,
             modified: [ItemStorageField] = ItemStorageField.all)
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
        let modified: [ItemStorageField]
    }
}

enum ItemStorageField: String
{
    case text, state, tag, root
    
    static let all: [ItemStorageField] = [text, state, tag, root]
}

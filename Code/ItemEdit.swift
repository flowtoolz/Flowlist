import SwiftObserver

enum ItemEdit
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
    case didCreate(_ info: ItemEditInfo)
    case didModify(_ info: ItemEditInfo)
    case didDelete(id: String)
}

extension ItemData
{
    convenience init(from editInfo: ItemEditInfo)
    {
        self.init(id: editInfo.id)
        
        text <- editInfo.text
        state <- State(from: editInfo.state)
        tag <- Tag(from: editInfo.tag)
    }
}

struct ItemEditInfo
{
    init(id: String,
         text: String? = nil,
         state: Int? = nil,
         tag: Int? = nil,
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
    let state: Int?
    let tag: Int?
    let rootId: String?
    let modified: [ItemStorageField]
}

enum ItemStorageField: String
{
    case text, state, tag, root
    
    static let all: [ItemStorageField] = [text, state, tag, root]
}

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

struct ItemEditInfo
{
    init(data: ItemData,
         rootId: String?,
         modified: [ItemStorageField] = ItemStorageField.all)
    {
        self.data = data
        self.rootId = rootId
        self.modified = modified
    }
    
    let data: ItemData
    let rootId: String?
    
    let modified: [ItemStorageField]
}

enum ItemStorageField: String
{
    case text, state, tag, root
    
    static let all: [ItemStorageField] = [text, state, tag, root]
}

import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == ItemDatabaseEvent
{
    
}

enum ItemDatabaseEvent
{
    case didNothing
    case didCreate(_ info: ItemDatabaseUpdateInfo)
    case didModify(_ info: ItemDatabaseUpdateInfo)
    case didDelete(id: String)
}

struct ItemDatabaseUpdateInfo
{
    init(data: ItemData,
         rootId: String?,
         modified: [ItemDatabaseField] = ItemDatabaseField.all)
    
    {
        self.data = data
        self.rootId = rootId
        self.modified = modified
    }
    
    let data: ItemData
    let rootId: String?
    
    let modified: [ItemDatabaseField]
}

enum ItemDatabaseField
{
    case text, state, tag, root
    
    static let all: [ItemDatabaseField] = [text, state, tag, root]
}

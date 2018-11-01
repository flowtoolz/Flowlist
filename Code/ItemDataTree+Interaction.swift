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
        init(from treeEdit: Messenger.Event.TreeEdit)
        {
            switch treeEdit
            {
            case .remove(let nodes, _):
                let ids = nodes.compactMap { $0.data.id }
                self = .removeNodesWithIds(ids)
                
            case .insert(let nodes, let root, _):
                let mods = nodes.compactMap { Modification(from: $0) }
                self = .insertNodes(mods, inNodeWithId: root.data.id)
            }
        }
        
        case none
        case insertNodes([Modification], inNodeWithId: String?)
        case modifyNode(Modification)
        case removeNodesWithIds([String])
    }
    
    struct Modification
    {
        init(from itemDataTree: ItemDataTree, modified: [Field] = Field.all)
        {
            let data = itemDataTree.data

            self.init(id: data.id,
                      text: itemDataTree.text,
                      state: data.state.value,
                      tag: data.tag.value,
                      rootId: itemDataTree.root?.data.id,
                      modified: modified)
        }
        
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

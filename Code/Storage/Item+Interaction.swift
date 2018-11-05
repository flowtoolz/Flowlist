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
        init?(from treeUpdate: Event.TreeUpdate)
        {
            switch treeUpdate
            {
            case .removedNodes(let nodes, _):
                let ids = nodes.compactMap { $0.data.id }
                self = .removeItemsWithIds(ids)
                
            case .insertedNodes(let nodes, let root, _):
                let mods = nodes.compactMap { Modification(from: $0) }
                self = .insertItem(mods, inItemWithId: root.data.id)
            
            case .receivedDataUpdate(let dataUpdate, let node):
                if case .wasModified = dataUpdate
                {
                    self = .modifyItem(Modification(from: node))
                }
                else { return nil }
            }
        }

        case insertItem([Modification], inItemWithId: String?)
        case modifyItem(Modification)
        case removeItemsWithIds([String])
    }
    
    struct Modification
    {
        init(from itemDataTree: Item, modified: [Field] = Field.allCases)
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
             modified: [Field] = Field.allCases)
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
    
    enum Field: String, CaseIterable
    {
        case text, state, tag, root
    }
}

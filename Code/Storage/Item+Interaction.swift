import SwiftObserver

// TODO: Modification and Interaction seem more generel and low level than Item. Maybe they should not depend on Item but be top level types. The convenience initializers to convert between Item and Modification can be in a separate extension. -> database, storage controller etc don't need to depend on Item when they know about Interaction + Modification...
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
    
    var modification: Modification
    {
        return Modification(id: data.id,
                            text: text,
                            state: data.state.value,
                            tag: data.tag.value,
                            rootId: root?.data.id)
    }
    
    enum Interaction
    {
        init?(from treeUpdate: Event.TreeUpdate)
        {
            switch treeUpdate
            {
            case .insertedNodes(let nodes, let root, _):
                let mods = nodes.allItems.compactMap { $0.modification }
                self = .insertItem(mods, inItemWithId: root.data.id)
            
            case .receivedDataUpdate(let dataUpdate, let node):
                if case .wasModified = dataUpdate
                {
                    self = .modifyItem(node.modification)
                }
                else { return nil }
                
            case .removedNodes(let nodes, _):
                let ids = nodes.allItems.compactMap { $0.data.id }
                self = .removeItemsWithIds(ids)
            }
        }

        case insertItem([Modification], inItemWithId: String?)
        case modifyItem(Modification)
        case removeItemsWithIds([String])
    }
    
    struct Modification
    {
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

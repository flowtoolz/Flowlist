enum Edit
{
    init?(from treeUpdate: Item.Event.TreeUpdate)
    {
        switch treeUpdate
        {
        case .insertedNodes(let nodes, let root, _):
            let mods = nodes.allItems.compactMap { $0.modification }
            self = .insertItem(mods, inItemWithId: root.data.id)
            
        case .receivedDataUpdate(let dataUpdate, let node):
            if case .wasModified = dataUpdate
            {
                var modification = node.modification
                modification.modified = [.text, .state, .tag]
                self = .modifyItem(modification)
            }
            else { return nil }
            
        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.data.id }
            self = .removeItemsWithIds(ids)
            
        case .movedNode(let node, _, _):
            var modification = node.modification
            modification.modified = [.position]
            self = .modifyItem(modification)
        }
    }
    
    case insertItem([Modification], inItemWithId: String?)
    case modifyItem(Modification)
    case removeItemsWithIds([String])
}

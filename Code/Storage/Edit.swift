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
                self = .modifyItem(node.modification)
            }
            else { return nil }
            
        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.data.id }
            self = .removeItemsWithIds(ids)
            
        case .movedNode(let node, _, _):
            self = .modifyItem(node.modification)
        }
    }
    
    case insertItem([Modification], inItemWithId: String?)
    case modifyItem(Modification)
    case removeItemsWithIds([String])
}

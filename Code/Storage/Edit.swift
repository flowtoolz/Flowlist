enum Edit
{
    init?(treeUpdate: Item.Event.TreeUpdate)
    {
        switch treeUpdate
        {
        case .insertedNodes(let nodes, let root, _):
            var mods = [Modification]()
            
            for item in nodes
            {
                mods.append(contentsOf: item.modifications())
            }
            
            self = .insertItems(mods, inItemWithId: root.data.id)
            
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
    
    case insertItems([Modification], inItemWithId: String)
    case modifyItem(Modification)
    case removeItemsWithIds([String])
}

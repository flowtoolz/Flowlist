enum Edit
{
    init?(from treeUpdate: Item.Event.TreeUpdate)
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
    
    case insertItems([Modification], inItemWithId: String)
    case modifyItem(Modification)
    case removeItemsWithIds([String])
}

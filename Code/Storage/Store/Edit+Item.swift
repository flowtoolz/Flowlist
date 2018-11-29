extension Edit
{
    init?(treeUpdate: Item.Event.TreeUpdate)
    {
        switch treeUpdate
        {
        case .insertedNodes(let nodes, _, _):
            var mods = [Modification]()
            
            nodes.forEach
            {
                mods.append(contentsOf: $0.modifications())
            }
            
            self = .updateItems(withModifications: mods)
            
        case .receivedDataUpdate(let dataUpdate, let node):
            if case .wasModified = dataUpdate
            {
                let mod = node.modification(modifiesPosition: false)
                self = .updateItems(withModifications: [mod])
            }
            else
            {
                return nil
            }
            
        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.data.id }
            self = .removeItems(withIDs: ids)
            
        case .movedNode(let node, _, _):
            self = .updateItems(withModifications: [node.modification()])
        }
    }
}

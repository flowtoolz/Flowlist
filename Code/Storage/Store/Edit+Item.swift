extension Edit
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
            
            self = .insertItems(withModifications: mods,
                                inRootWithID: root.data.id)
            
        case .receivedDataUpdate(let dataUpdate, let node):
            if case .wasModified = dataUpdate
            {
                let modification = node.modification(modifiesPosition: false)
                self = .modifyItem(withModification: modification)
            }
            else { return nil }
            
        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.data.id }
            self = .removeItems(withIDs: ids)
            
        case .movedNode(let node, _, _):
            self = .modifyItem(withModification: node.modification())
        }
    }
}

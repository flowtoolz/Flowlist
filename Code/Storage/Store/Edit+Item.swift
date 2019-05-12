extension Edit
{
    init?(treeUpdate: Item.Event.TreeUpdate)
    {
        switch treeUpdate
        {
        case .insertedNodes(let nodes, _, _):
            var records = [Record]()
            
            nodes.forEach
            {
                records.append(contentsOf: $0.makeRecords())
            }
            
            self = .updateItems(withRecords: records)
            
        case .receivedMessage(let dataUpdate, let node):
            if case .wasModified = dataUpdate
            {
                let record = node.makeRecord(modifiesPosition: false)
                self = .updateItems(withRecords: [record])
            }
            else
            {
                return nil
            }
            
        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.data.id }
            self = .removeItems(withIDs: ids)
            
        case .movedNode(let node, _, _):
            self = .updateItems(withRecords: [node.makeRecord()])
        }
    }
}

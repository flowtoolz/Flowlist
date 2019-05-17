extension Tree.Event.TreeUpdate where Data == ItemData
{
    func makeEdit() -> Edit?
    {
        switch self
        {
        case .insertedNodes(let nodes, _, _):
            let records = nodes.flatMap { $0.makeRecords() }
            return .updateItems(withRecords: records)
            
        case .receivedMessage(let dataUpdate, let node):
            guard case .wasModified = dataUpdate else { return nil }
            let record = node.makeRecord(modifiesPosition: false)
            return .updateItems(withRecords: [record])
            
        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.data.id }
            return .removeItems(withIDs: ids)
            
        case .movedNode(let node, _, _):
            return .updateItems(withRecords: [node.makeRecord()])
        }
    }
}

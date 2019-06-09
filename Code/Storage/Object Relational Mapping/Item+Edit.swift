import SwiftyToolz

extension Tree.Event.TreeUpdate where Data == ItemData
{
    func makeEdit() -> Edit?
    {
        switch self
        {
        case .insertedNodes(let nodes, _, _):
            let records = nodes.flatMap { $0.makeRecordsRecursively() }
            return .updateItems(withRecords: records)
            
        case .receivedMessage(let dataUpdate, let node):
            switch dataUpdate
            {
            case .didNothing, .wantTextInput:
                return nil
            case .wasModified:
                let record = node.makeRecord(modifiesPosition: false)
                return .updateItems(withRecords: [record])
            }

        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.data.id }
            return .removeItems(withIDs: ids)
            
        case .movedNode(let node, let from, let to):
            guard let parent = node.root else
            {
                log(error: "Tree says a node moved position, but the node has no root node.")
                return nil
            }
            
            let fromIsSmaller = from < to
            let firstMovedIndex = fromIsSmaller ? from : to
            let lastMovedIndex = fromIsSmaller ? to : from
            
            guard parent.branches.count > lastMovedIndex else
            {
                log(error: "Tree says a node moved to- or from out of bounds index.")
                return nil
            }
            
            let movedItems = parent.branches[firstMovedIndex ... lastMovedIndex]
            let movedRecords = movedItems.map { $0.makeRecord() }
            
            return .updateItems(withRecords: movedRecords)
        }
    }
}

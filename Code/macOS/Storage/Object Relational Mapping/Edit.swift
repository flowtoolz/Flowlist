import SwiftyToolz

enum Edit
{
    init?(_ itemTreeUpdate: Item.Event.TreeUpdate)
    {
        switch itemTreeUpdate
        {
        case .insertedNodes(let nodes, _, _):
            let records = nodes.flatMap { Record.makeRecordsRecursively(for: $0) }
            self = .updateItems(withRecords: records)
            
        case .receivedMessage(let dataUpdate, let node):
            switch dataUpdate
            {
            case .didNothing, .wantTextInput:
                return nil
            case .wasModified:
                self = .updateItems(withRecords: [Record(item: node)])
            }
            
        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.data.id }
            self = .removeItems(withIDs: ids)
            
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
            let movedRecords = movedItems.map(Record.init)
            
            self = .updateItems(withRecords: movedRecords)
        }
    }
    
    case updateItems(withRecords: [Record])
    case removeItems(withIDs: [String])
}

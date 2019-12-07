import PromiseKit
import SwiftObserver
import SwiftyToolz

class RecordController: Observer
{
    // MARK: - Life cycle
    
    init()
    {
        observeRecordStore()
        observeItemStore()
    }
    
    // MARK: - Transmit Record Store Changes to Item Store
    
    private func observeRecordStore()
    {
        observe(RecordStore.shared)
        {
            [weak self] event, author in
            
            guard let self = self, author !== self else { return }
        
            self.recordStoreDidSend(event)
        }
    }
    
    private func recordStoreDidSend(_ event: RecordStore.Event)
    {
        switch event
        {
        case .didDeleteRecordsWithIDs(let ids):
            TreeStore.shared.deleteItems(with: ids)
            
        case .didModifyRecords(let records):
            let updates = records.map { $0.makeUpdate() }
            TreeStore.shared.apply(updates: updates)
        }
    }
    
    // MARK: - Transmit Tree Store Changes to Record Store
    
    private func observeItemStore()
    {
        observe(TreeStore.shared)
        {
            [weak self] in self?.itemStoreDidSend($0)
        }
    }
    
    private func itemStoreDidSend(_ event: TreeStore.Event)
    {
        switch event {
        case .willApplyMultipleUpdates, .didApplyMultipleUpdates:
            break
            
        case .treeDidUpdate(let update):
            tree(did: update)
            
        case .didAddTree(let tree):
            let records = tree.allNodesRecursively.map(Record.init)
            RecordStore.shared.save(records, as: self)
            
        case .didRemoveTree(let tree):
            let ids = tree.allNodesRecursively.map { $0.id }
            RecordStore.shared.deleteRecords(with: ids, as: self)
        }
    }
    
    private func tree(did update: Item.Event.TreeUpdate)
    {
        switch update
        {
        case .insertedNodes(let insertedChildren, let parent, _, let lastPosition):
            var allEffectedItems = insertedChildren.flatMap { $0.allNodesRecursively }
            let indicesOfRepositionedItems = Array(lastPosition + 1 ..< parent.count)
            allEffectedItems += parent[indicesOfRepositionedItems]
            let effectedRecords = allEffectedItems.map(Record.init)
            RecordStore.shared.save(effectedRecords, as: self)
            
        case .receivedMessage(let message, let node):
            if case .wasModified = message
            {
                RecordStore.shared.save([Record(item: node)], as: self)
            }
            
        case .removedNodes(let removedChildren, let parent):
            let allRemovedItems = removedChildren.flatMap { $0.allNodesRecursively }
            let idsOfAllRemovedItems = allRemovedItems.map { $0.id }
            RecordStore.shared.deleteRecords(with: idsOfAllRemovedItems, as: self)
            let possiblyRepositionedRecords = parent.children.map(Record.init)
            RecordStore.shared.save(possiblyRepositionedRecords, as: self)
            
        case .movedNode(let node, let from, let to):
            guard let parent = node.parent else
            {
                log(error: "Tree says a node moved position, but the node has no parent.")
                break
            }
            
            let fromIsSmaller = from < to
            let firstRepositionedIndex = fromIsSmaller ? from : to
            let lastRepositionedIndex = fromIsSmaller ? to : from
            
            guard parent.children.count > lastRepositionedIndex else
            {
                log(error: "Tree says a node moved to- or from an out of bounds index.")
                break
            }
            
            let repositionedItems = parent.children[firstRepositionedIndex ... lastRepositionedIndex]
            let repositionedRecords = repositionedItems.map(Record.init)
            
            RecordStore.shared.save(repositionedRecords, as: self)
        }
    }
    
    // MARK: - Observer
    
    let receiver = Receiver()
}

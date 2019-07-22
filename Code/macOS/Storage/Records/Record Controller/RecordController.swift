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
    
    deinit { stopObserving() }
    
    // MARK: - Transmit Record Store Changes to Item Store
    
    private func observeRecordStore()
    {
        observe(RecordStore.shared).filter
        {
            [weak self] event in event != nil && event?.object !== self
        }
        .map
        {
            event in event?.did
        }
        .unwrap(.modifyRecords([]))
        {
            [weak self] edit in self?.recordStore(did: edit)
        }
    }
    
    private func recordStore(did edit: RecordStore.Edit)
    {
        switch edit
        {
        case .deleteRecordsWithIDs(let ids):
            TreeStore.shared.deleteItems(withIDs: ids)
            
        case .modifyRecords(let records):
            let updates = records.map { $0.makeUpdate() }
            TreeStore.shared.apply(updates: updates)
        }
    }
    
    // MARK: - Transmit Item Store Changes to Record Store
    
    private func observeItemStore()
    {
        observe(TreeStore.shared)
        {
            [weak self] in
            
            guard let event = $0, case .someTreeDidChange(let treeUpdate) = event else { return }
            
            self?.itemStoreDid(treeUpdate)
        }
    }
    
    private func itemStoreDid(_ update: Item.Event.TreeUpdate)
    {
        switch update
        {
        case .insertedNodes(let items, _, _):
            let records = items.flatMap { Record.makeRecordsRecursively(for: $0) }
            RecordStore.shared.save(records, identifyAs: self)
            
        case .receivedMessage(let message, let node):
            if case .wasModified = message
            {
                RecordStore.shared.save([Record(item: node)], identifyAs: self)
            }
            
        case .removedNodes(let items, _):
            let allRemovedItems = items.flatMap { $0.allNodesRecursively }
            let ids = allRemovedItems.map { $0.id }
            RecordStore.shared.deleteRecords(with: ids, identifyAs: self)
            
        case .movedNode(let node, let from, let to):
            guard let parent = node.root else
            {
                log(error: "Tree says a node moved position, but the node has no root node.")
                break
            }
            
            let fromIsSmaller = from < to
            let firstMovedIndex = fromIsSmaller ? from : to
            let lastMovedIndex = fromIsSmaller ? to : from
            
            guard parent.branches.count > lastMovedIndex else
            {
                log(error: "Tree says a node moved to- or from out of bounds index.")
                break
            }
            
            let movedItems = parent.branches[firstMovedIndex ... lastMovedIndex]
            let movedRecords = movedItems.map(Record.init)
            
            RecordStore.shared.save(movedRecords, identifyAs: self)
        }
    }
}

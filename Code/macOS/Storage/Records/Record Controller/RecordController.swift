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
            ItemStore.shared.deleteItems(withIDs: ids)
            
        case .modifyRecords(let records):
            let updates = records.map { $0.makeUpdate() }
            ItemStore.shared.apply(updates: updates)
        }
    }
    
    // MARK: - Transmit Item Store Changes to Record Store
    
    private func observeItemStore()
    {
        observe(ItemStore.shared).filter
        {
            event in event != nil
        }
        .unwrap(.didSwitchRoot)
        {
            [weak self] event in self?.itemStoreDidSend(event)
        }
    }
    
    private func itemStoreDidSend(_ event: ItemStore.Event)
    {
        switch event
        {
        case .didUpdate(let update):
            itemStoreDid(update)
            
        case .didSwitchRoot:
            // TODO: should we do anything? can this happen after setup?
            log(warning: "Item Store did switch root. We might nbeed to respond if this happens not just on app launch.")
            break
        }
    }
    
    private func itemStoreDid(_ update: Item.Event.TreeUpdate)
    {
        switch update
        {
        case .insertedNodes(let nodes, _, _):
            let records = nodes.flatMap { Record.makeRecordsRecursively(for: $0) }
            RecordStore.shared.save(records, identifyAs: self)
            
        case .receivedMessage(let message, let node):
            if case .wasModified = message
            {
                RecordStore.shared.save([Record(item: node)], identifyAs: self)
            }
            
        case .removedNodes(let nodes, _):
            let ids = nodes.compactMap { $0.id }
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

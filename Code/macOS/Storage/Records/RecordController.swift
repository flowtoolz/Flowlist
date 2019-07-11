import PromiseKit
import SwiftObserver
import SwiftyToolz

class RecordController: Observer
{
    // MARK: - Life cycle
    
    init() { observeStores() }
    deinit { stopObserving() }
    
    // MARK: - Observe Record- and Item Store
    
    private func observeStores()
    {
        observeRecordStore()
        
        observe(ItemStore.shared)
        {
            [weak self] in if let event = $0 { self?.itemStoreDidSend(event) }
        }
    }
    
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
            ItemStore.shared.apply(.removeItems(withIDs: ids))
            
        case .modifyRecords(let records):
            ItemStore.shared.apply(.updateItems(withRecords: records))
        }
    }
    
    // MARK: - Transmit Item Store Changes to Record Store
    
    private func itemStoreDidSend(_ itemStoreEvent: ItemStore.Event?)
    {
        guard let itemStoreEvent = itemStoreEvent else { return }
        
        switch itemStoreEvent
        {
        case .didUpdate(let update):
            if let edit = Edit(update)
            {
                switch edit
                {
                case .updateItems(let records):
                    RecordStore.shared.save(records, identifyAs: self)
                    
                case .removeItems(let ids):
                    RecordStore.shared.deleteRecords(with: ids, identifyAs: self)
                }
            }
            
        case .didSwitchRoot:
            // TODO: should we do anything? can this happen after setup?
            log(warning: "Item Store did switch root. We might nbeed to respond if this happens not just on app launch.")
            break
        }
    }
}

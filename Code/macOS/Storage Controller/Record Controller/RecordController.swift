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
        observe(RecordStore.shared)
        {
            [weak self] in if let event = $0 { self?.recordStoreDidSend(event) }
        }
        
        observe(ItemStore.shared)
        {
            [weak self] in if let event = $0 { self?.itemStoreDidSend(event) }
        }
    }
    
    // MARK: - Transmit Record Store Changes to Item Store
    
    private func recordStoreDidSend(_ event: RecordStore.Event)
    {
        switch event
        {
        case .didDeleteRecordsWithIDs(let ids):
            ItemStore.shared.apply(.removeItems(withIDs: ids))
            
        case .didSaveRecords(let records):
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
                    RecordStore.shared.save(records)
                    
                case .removeItems(let ids):
                    RecordStore.shared.deleteRecords(with: ids)
                }
            }
            
        case .didSwitchRoot:
            // TODO: should we do anything? can this happen after setup?
            log(warning: "Item Store did switch root. We might nbeed to respond if this happens not just on app launch.")
            break
        }
    }
}

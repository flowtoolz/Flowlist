import CloudKit
import SwiftObserver

extension ItemICloudDatabase: ItemDatabase
{
    // MARK: - Apply Edits
    
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .insertItems(let modifications, let rootID):
            insertItems(with: modifications, inRootWithID: rootID)
            
        case .modifyItem(let modification, let rootID):
            modifyItem(with: modification, inRootWithID: rootID)
            
        case .removeItems(let ids):
            removeItems(with: ids)
        }
    }
    
    // MARK: - Manage the Root
    
    func resetItemTree(with root: Item)
    {
        removeItems
        {
            guard $0 else { return }
            
            let records: [CKRecord] = root.array.map
            {
                CKRecord(modification: $0.modification(),
                         superItem: $0.root?.data.id)
            }
            
            self.save(records)
            {
                guard $0 else
                {
                    log(error: "Couldn't save records.")
                    return
                }
            }
        }
    }
    
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    {
        fetchItemRecords()
        {
            guard let records = $0 else
            {
                log(error: "Couldn't fetch records.")
                return
            }
            
            receiveRoot(Item(records: records))
        }
    }
}

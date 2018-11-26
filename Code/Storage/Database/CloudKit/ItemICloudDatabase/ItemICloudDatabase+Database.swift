import CloudKit
import SwiftObserver

extension ItemICloudDatabase: Database
{
    // MARK: - Apply Edits
    
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .insertItems(let modifications, let rootID):
            insertItems(with: modifications, inRootWithID: rootID)
            
        case .modifyItem(let modification):
            modifyItem(with: modification)
            
        case .removeItems(let ids):
            removeItems(with: ids)
        }
    }
    
    // MARK: - Manage the Root
    
    func resetItemTree(with root: Item,
                       handleSuccess: @escaping (Bool) -> Void)
    {
        removeItems
        {
            guard $0 else
            {
                log(error: "Couldn't remove records.")
                handleSuccess(false)
                return
            }
            
            let records: [CKRecord] = root.array.map
            {
                CKRecord(modification: $0.modification())
            }
            
            self.save(records)
            {
                guard $0 else
                {
                    log(error: "Couldn't save records.")
                    handleSuccess(false)
                    return
                }
                
                handleSuccess(true)
            }
        }
    }
    
    func fetchItemTree(handleResult: @escaping (_ success: Bool, _ root: Item?) -> Void)
    {
        fetchItemRecords
        {
            guard let records = $0 else
            {
                log(error: "Couldn't fetch records.")
                handleResult(false, nil)
                return
            }
            
            guard !records.isEmpty else
            {
                handleResult(true, nil)
                return
            }
            
            guard let root = Item(records: records) else
            {
                log(error: "Couldn't create item tree from records.")
                handleResult(false, nil)
                return
            }
            
            handleResult(true, root)
        }
    }
}

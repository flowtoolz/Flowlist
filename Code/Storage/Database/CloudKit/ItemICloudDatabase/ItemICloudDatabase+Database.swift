import CloudKit
import SwiftObserver

extension ItemICloudDatabase: Database
{
    // MARK: - Apply Edits
    
    func apply(_ edit: Edit)
    {
        switch edit
        {
        case .updateItems(let modifications):
            let modsByRootID = getModsByRootID(from: modifications)
            
            for (rootID, mods) in modsByRootID
            {
                updateItems(with: mods, inRootWithID: rootID)
                {
                    _ in
                    
                    self.updateServerChangeToken()
                }
            }
            
        case .removeItems(let ids):
            removeItems(with: ids)
            {
                _ in
             
                self.updateServerChangeToken()
            }
        }
    }
    
    // MARK: - Item Updates
    
    private func getModsByRootID(from mods: [Modification]) -> [String : [Modification]]
    {
        var resultDictionary = [String : [Modification]]()
        
        for mod in mods
        {
            guard let rootID = mod.rootID else
            {
                log(warning: "Modification has no root ID.")
                continue
            }
            
            if resultDictionary[rootID] == nil
            {
                resultDictionary[rootID] = [Modification]()
            }
            
            resultDictionary[rootID]?.append(mod)
        }
        
        return resultDictionary
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
                
                self.updateServerChangeToken()
                
                handleSuccess(true)
            }
        }
    }
    
    func fetchItemTree(handleResult: @escaping (_ success: Bool, _ root: Item?) -> Void)
    {
        fetchAllItemRecords
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
    
    // MARK: - Kepp Server Change Token Up To Date
    
    private func updateServerChangeToken()
    {
        updateServerChangeToken(zoneID: CKRecordZone.ID.item,
                                oldToken: serverChangeToken) { _ in }
    }
}

import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase: ItemDatabase
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
                log(error: "Modification has no root ID.")
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
            
            firstly {
                self.save(records)
            }.done { _ in
                self.updateServerChangeToken()
                handleSuccess(true)
            }.catch { error in
                log(error)
                handleSuccess(false)
            }
        }
    }
    
    func fetchItemTree(handleResult: @escaping ItemTreeHandler)
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
    
    // MARK: - Keep Server Change Token Up To Date
    
    private func updateServerChangeToken()
    {
        firstly {
            fetchNewUpdates()
        }.catch { 
            log($0)
        }
    }
}

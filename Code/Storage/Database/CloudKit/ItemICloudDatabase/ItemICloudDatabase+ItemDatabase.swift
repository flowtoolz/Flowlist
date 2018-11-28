import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase: ItemDatabase
{
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
    
    private func updateServerChangeToken()
    {
        firstly {
            fetchNewUpdates()
        }.catch {
            log($0)
        }
    }
    
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
}

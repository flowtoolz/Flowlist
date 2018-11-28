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
                firstly {
                    self.updateItems(with: mods, inRootWithID: rootID)
                }.then { _ in
                    self.fetchNewUpdates()
                }.catch {
                    log($0)
                }
            }
            
        case .removeItems(let ids):
            firstly {
                self.removeItems(with: ids)
            }.then { _ in
                self.fetchNewUpdates()
            }.catch {
                log($0)
            }
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

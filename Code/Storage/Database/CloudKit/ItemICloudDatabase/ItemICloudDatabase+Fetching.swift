import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase
{
    func fetchTrees() -> Promise<MakeTreesResult>
    {
        return Promise<MakeTreesResult>
        {
            resolver in

            firstly
            {
                fetchAllItemRecords()
            }
            .map(on: backgroundQ)
            {
                $0.map(Record.init).makeTrees()
            }
            .done(on: backgroundQ)
            {
                resolver.fulfill($0)
            }
            .catch(on: backgroundQ)
            {
                resolver.reject($0.storageError)
            }
        }
    }
    
    private func fetchAllItemRecords() -> Promise<[CKRecord]>
    {
        return fetchAllUpdates().map(on: backgroundQ)
        {
            $0.changedRecords
        }
    }
    
    func fetchUpdates() -> Promise<[Edit]>
    {
        return Promise<[Edit]>
        {
            resolver in
            
            firstly
            {
                self.fetchNewUpdates()
            }
            .map(on: backgroundQ)
            {
                (result: ChangeFetch.Result) -> [Edit] in
                
                var edits = [Edit]()
                
                if result.idsOfDeletedRecords.count > 0
                {
                    let ids = result.idsOfDeletedRecords.map { $0.recordName }
                    edits.append(.removeItems(withIDs: ids))
                }
                
                if result.changedRecords.count > 0
                {
                    let records = result.changedRecords.map(Record.init)
                    
                    edits.append(.updateItems(withRecords: records))
                }
                
                return edits
            }
            .done(on: backgroundQ)
            {
                resolver.fulfill($0)
            }
            .catch(on: backgroundQ)
            {
                resolver.reject($0.storageError)
            }
        }
    }
}

fileprivate extension Error
{
    var storageError: StorageError
    {
        let message = "This issue came up: \(self.localizedDescription)"
        
        return StorageError.message(message)
    }
}

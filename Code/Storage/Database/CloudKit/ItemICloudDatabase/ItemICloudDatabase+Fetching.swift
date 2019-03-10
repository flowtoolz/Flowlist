import CloudKit
import SwiftObserver
import PromiseKit

extension ItemICloudDatabase: ItemDatabase
{
    func fetchRecords() -> Promise<FetchRecordsResult>
    {
        return Promise<FetchRecordsResult>
        {
            resolver in
            
            let oldToken = db.serverChangeToken
            
            firstly
            {
                fetchAllChanges()
            }
            .map(on: backgroundQ)
            {
                (result: ChangeFetch.Result) -> FetchRecordsResult in
                
                let records = result.changedRecords.map(Record.init)
                let wasModified = oldToken != self.db.serverChangeToken
                
                return FetchRecordsResult(records: records,
                                          dbWasModified: wasModified)
            }
            .done(on: backgroundQ, resolver.fulfill).catch(on: backgroundQ)
            {
                resolver.reject($0.storageError)
            }
        }
    }
  
    func fetchUpdates() -> Promise<[Edit]>
    {
        return Promise<[Edit]>
        {
            resolver in
            
            firstly
            {
                self.fetchNewChanges()
            }
            .map(on: backgroundQ)
            {
                (result: ChangeFetch.Result) -> [Edit] in
                
                var edits = [Edit]()
                
                if result.idsOfDeletedRecords.count > 0
                {
                    let ids = result.idsOfDeletedRecords.map
                    {
                        $0.recordName
                    }
                    
                    edits.append(.removeItems(withIDs: ids))
                }
                
                if result.changedRecords.count > 0
                {
                    let records = result.changedRecords.map(Record.init)
                    
                    edits.append(.updateItems(withRecords: records))
                }
                
                return edits
            }
            .done(on: backgroundQ, resolver.fulfill).catch(on: backgroundQ)
            {
                resolver.reject($0.storageError)
            }
        }
    }
}

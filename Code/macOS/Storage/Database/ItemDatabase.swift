import SwiftObserver
import PromiseKit

protocol ItemDatabase
{
    func fetchRecords() -> Promise<[Record]>
    
    func fetchChanges() -> Promise<ItemDatabaseChanges>
    var hasChangeToken: Bool { get }
    
    func reset(with records: [Record]) -> Promise<ItemDatabaseSaveResult>
    func save(_ records: [Record]) -> Promise<ItemDatabaseSaveResult>
    func deleteRecords(withIDs ids: [String]) -> Promise<ItemDatabaseDeletionResult>
    
    var queue: DispatchQueue { get }
    
    var messenger: Messenger<ItemDatabaseUpdate?> { get }
}

enum ItemDatabaseUpdate { case mayHaveChanged }

struct ItemDatabaseChanges
{
    let modifiedRecords: [Record]
    let idsOfDeletedRecords: [String]
    var hasChanges: Bool { return modifiedRecords.count + idsOfDeletedRecords.count > 0 }
}

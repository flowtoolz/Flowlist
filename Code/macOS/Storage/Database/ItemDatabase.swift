import SwiftObserver
import PromiseKit

protocol ItemDatabase
{
    func fetchRecords() -> Promise<[Record]>
    
    func fetchChanges() -> Promise<ItemDatabaseChanges>
    var hasChangeToken: Bool { get }
    
    func reset(root: Item?) -> Promise<Void>
    func save(_ records: [Record]) -> Promise<ItemDatabaseSaveResult>
    func deleteRecords(with ids: [String]) -> Promise<ItemDatabaseDeletionResult>
    
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

enum ItemDatabaseSaveResult { case success }

struct ItemDatabaseDeletionResult
{
    static var empty: ItemDatabaseDeletionResult
    {
        return ItemDatabaseDeletionResult(idsOfDeletedRecords: [], failures: [])
    }
    
    let idsOfDeletedRecords: [String]
    let failures: [ItemDatabaseDeletionFailure]
}

struct ItemDatabaseDeletionFailure
{
    let recordID: String
    let error: Error
}

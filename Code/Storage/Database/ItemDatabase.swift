import SwiftObserver
import PromiseKit

protocol ItemDatabase
{
    func reset(root: Item?) -> Promise<Void>
    func apply(_ edit: Edit) -> Promise<Void>
    
    func fetchRecords() -> Promise<[Record]>
    func fetchChanges() -> Promise<ItemDatabaseChanges>
    
    var messenger: Messenger<ItemDatabaseUpdate> { get }
    
    func ensureAccess() -> Promise<Void>
    var isCheckingAccess: Bool { get }
    var didEnsureAccess: Bool { get }
}

enum ItemDatabaseUpdate { case mayHaveChanged }

struct ItemDatabaseChanges
{
    let modifiedRecords: [Record]
    let idsOfDeletedRecords: [String]
    let thisAppDidTheChanges: Bool
    var hasChanges: Bool { return modifiedRecords.count + idsOfDeletedRecords.count > 0 }
}

import SwiftObserver
import PromiseKit

protocol ItemDatabase
{
    func fetchRecords() -> Promise<[Record]>
    
    func fetchChanges() -> Promise<ItemDatabaseChanges>
    var hasChangeToken: Bool { get }
    
    func reset(root: Item?) -> Promise<Void>
    func apply(_ edit: Edit) -> Promise<Void>
    
    var messenger: Messenger<ItemDatabaseUpdate> { get }
}

enum ItemDatabaseUpdate { case mayHaveChanged }

struct ItemDatabaseChanges
{
    let modifiedRecords: [Record]
    let idsOfDeletedRecords: [String]
    let thisAppDidTheChanges: Bool
    var hasChanges: Bool { return modifiedRecords.count + idsOfDeletedRecords.count > 0 }
}

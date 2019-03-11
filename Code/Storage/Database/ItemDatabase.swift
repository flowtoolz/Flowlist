import SwiftObserver
import PromiseKit

protocol ItemDatabase: Database
{
    func fetchUpdates() -> Promise<[Edit]>
    func apply(_ edit: Edit) -> Promise<Void>
    
    func fetchRecords() -> Promise<FetchRecordsResult>
    func reset(tree: Item) -> Promise<Void>
    
    var messenger: Messenger<Edit?> { get }
    
    var isAccessible: Bool? { get }
}

struct FetchRecordsResult
{
    let records: [Record]
    let dbWasModified: Bool
}

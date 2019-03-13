import SwiftObserver
import PromiseKit

protocol ItemDatabase
{
    func fetchUpdates() -> Promise<[Edit]>
    func apply(_ edit: Edit) -> Promise<Void>
    
    func fetchRecords() -> Promise<FetchRecordsResult>
    func reset(tree: Item) -> Promise<Void>
    
    var messenger: Messenger<Edit?> { get }
    
    func checkAccess() -> Promise<Accessibility>
    var isCheckingAccess: Bool { get }
    var isAccessible: Var<Bool?> { get }
    
    var isReachable: Var<Bool?> { get }
}

struct FetchRecordsResult
{
    let records: [Record]
    let dbWasModified: Bool
}

enum Accessibility
{
    case accessible
    case inaccessible(_ message: String)
}

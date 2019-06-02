import SwiftObserver
import PromiseKit

protocol ItemDatabase
{
    func reset(root: Item) -> Promise<Void>
    func apply(_ edit: Edit) -> Promise<Void>
    func fetchRecords() -> Promise<[Record]>
    
    var messenger: Messenger<Edit?> { get }
    
    func ensureAccess() -> Promise<Void>
    var isCheckingAccess: Bool { get }
    var didEnsureAccess: Bool { get }
}

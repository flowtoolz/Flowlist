import PromiseKit
import SwiftObserver

protocol Database: AnyObject
{
    func ensureAccess() -> Promise<Accessibility>
    var isAccessible: Bool? { get }
    
    var isReachable: Var<Bool?> { get }
}

enum Accessibility
{
    case accessible
    case unaccessible(_ message: String)
}

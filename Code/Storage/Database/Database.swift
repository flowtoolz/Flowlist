import PromiseKit
import SwiftObserver

protocol Database: AnyObject
{
    var isReachable: Var<Bool?> { get }
}

enum Accessibility
{
    case accessible
    case unaccessible(_ message: String)
}

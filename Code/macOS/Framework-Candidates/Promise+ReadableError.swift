import PromiseKit
import SwiftyToolz

extension PromiseKit.Promise
{
    static func fail<T>(_ errorMessage: String) -> PromiseKit.Promise<T>
    {
        PromiseKit.Promise<T>(error: ReadableError(errorMessage))
    }
}

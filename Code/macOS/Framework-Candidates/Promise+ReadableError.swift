import PromiseKit
import SwiftyToolz

extension Promise
{
    static func fail<T>(_ errorMessage: String) -> Promise<T>
    {
        Promise<T>(error: ReadableError(errorMessage))
    }
}

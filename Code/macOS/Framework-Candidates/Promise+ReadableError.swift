import PromiseKit
import SwiftyToolz

extension Promise
{
    static func fail<T>(_ errorMessage: String) -> Promise<T>
    {
        return Promise<T>(error: ReadableError.message(errorMessage))
    }
}

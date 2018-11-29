import PromiseKit

protocol Database: AnyObject
{
    func checkAvailability() -> Promise<Availability>
    var isAvailable: Bool? { get }
}

enum Availability
{
    case available
    case unavailable(_ message: String)
}

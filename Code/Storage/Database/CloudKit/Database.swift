import SwiftObserver
import SwiftyToolz

protocol Database: class
{
    func checkAvailability(handleResult: @escaping AvailabilityHandler)
    var isAvailable: Bool? { get }
    func fetchUpdates(handleResult: @escaping UpdateHandler)
    func apply(_ edit: Edit)
    
    func fetchItemTree(handleResult: @escaping ItemTreeHandler)
    func resetItemTree(with root: Item,
                       handleSuccess: @escaping (Bool) -> Void)
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    
    var messenger: EditSender { get }
    
    typealias AvailabilityHandler = (_ available: Bool, _ error: String?) -> Void
    typealias ItemTreeHandler = (_ success: Bool, _ root: Item?) -> Void
    typealias UpdateHandler = (_ edits: [Edit]?) -> Void
}

class EditSender: Observable
{
    var latestUpdate: Edit? = nil
}

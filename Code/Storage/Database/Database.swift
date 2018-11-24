import SwiftObserver
import SwiftyToolz

protocol Database: class
{
    // status
    func checkAvailability(handleResult: @escaping (_ available: Bool, _ error: String?) -> Void)
    var isAvailable: Bool? { get }
    
    // general edits
    func apply(_ edit: Edit)
    
    // root management
    func fetchItemTree(handleResult: @escaping (_ success: Bool, _ root: Item?) -> Void)
    func resetItemTree(with root: Item,
                       handleSuccess: @escaping (Bool) -> Void)
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    
    // observing the database
    var messenger: EditSender { get }
}

class EditSender: Observable
{
    var latestUpdate: Edit? = nil
}

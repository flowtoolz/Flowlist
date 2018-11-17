import SwiftObserver
import SwiftyToolz

protocol Database: class
{
    // status
    func checkAvailability(handleResult: @escaping (_ available: Bool,_ message: String?) -> Void)
    
    // general edits
    func apply(_ edit: Edit)
    
    // root management
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    func resetItemTree(with root: Item)
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    
    // observing the database
    var messenger: DatabaseMessenger { get }
}

class DatabaseMessenger: Observable
{
    var latestUpdate: Edit? = nil
}

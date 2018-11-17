import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Edit?
{
    // status
    func checkAvailability(handleResult: @escaping (_ available: Bool, _ message: String?) -> Void)
    
    // general edits
    func apply(_ edit: Edit)
    
    // root management
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    func resetItemTree(with root: Item)
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
}

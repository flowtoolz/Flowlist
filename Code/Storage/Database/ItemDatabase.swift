import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Edit?
{
    // general edits
    func apply(_ edit: Edit)
    
    // root management
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    func resetItemTree(with modifications: [Modification])
}

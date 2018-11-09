import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Edit?
{
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    func resetItemTree(with modifications: [Modification])
    
    func apply(_ edit: Edit)
}

import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Item.Operation
{
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    func save(itemTree root: Item)
}

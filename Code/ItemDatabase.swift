import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable
    where UpdateType == ItemDataTree.Interaction
{
    func fetchItemTree(receiveRoot: @escaping (ItemDataTree?) -> Void)
    func save(itemTree root: ItemDataTree)
}

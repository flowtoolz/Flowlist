import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Edit?
{
    func createItems(with modifications: [Modification])
    func create(itemTree root: Item)
    
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    
    func modifyItem(with modification: Modification)
    
    func deleteItem(with id: String)
    func deleteItems(with ids: [String])
}

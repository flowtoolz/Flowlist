import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Item.Interaction?
{
    func createItems(with modifications: [Item.Modification])
    func create(itemTree root: Item)
    
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    
    func modifyItem(with modification: Item.Modification)
    
    func deleteItem(with id: String)
    func deleteItems(with ids: [String])
}

import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Item.Interaction?
{
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    
    func save(itemTree root: Item)
    
    func saveItems(with modifications: [Item.Modification])
    func saveItem(with modification: Item.Modification)
    
    func deleteItem(with id: String)
    func deleteItems(with ids: [String])
}

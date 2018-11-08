import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Edit?
{
    func createItems(with modifications: [Modification],
                     inRootWithID rootID: String)
    func modifyItem(with modification: Modification)
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)    
    func deleteItem(with id: String)
    func deleteItems(with ids: [String])
}

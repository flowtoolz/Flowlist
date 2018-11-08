import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == Edit?
{
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
    func resetItemTree(with modifications: [Modification])
    
    func createItems(with modifications: [Modification],
                     inRootWithID rootID: String)
    func modifyItem(with modification: Modification)
    func deleteItem(with id: String)
    func deleteItems(with ids: [String])
}

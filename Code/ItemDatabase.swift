import SwiftObserver
import SwiftyToolz

protocol ItemDatabase: Observable where UpdateType == ItemEdit
{
    // TODO: declare whatever functionality the StorageController needs from the ItemDatabase
    
    func fetchItemTree(receiveRoot: @escaping (Item?) -> Void)
}

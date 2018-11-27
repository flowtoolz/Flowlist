import SwiftObserver
import SwiftyToolz
import PromiseKit

protocol ItemDatabase: Database
{
    func fetchUpdates(handleResult: @escaping UpdateHandler)
    func apply(_ edit: Edit)
    
    func fetchItemTree(handleResult: @escaping ItemTreeHandler)
    func resetItemTree(with root: Item,
                       handleSuccess: @escaping (Bool) -> Void)
    func removeItems(handleSuccess: @escaping (Bool) -> Void)
    
    var messenger: EditSender { get }
    
    typealias ItemTreeHandler = (_ success: Bool, _ root: Item?) -> Void
    typealias UpdateHandler = (_ edits: [Edit]?) -> Void
}

class EditSender: Observable
{
    var latestUpdate: Edit? = nil
}

import SwiftObserver
import SwiftyToolz
import PromiseKit

protocol ItemDatabase: Database
{
    func fetchUpdates() -> Promise<[Edit]>
    func apply(_ edit: Edit)
    
    func fetchItemTree(handleResult: @escaping ItemTreeHandler)
    func resetItemTree(with root: Item) -> Promise<Void>
    
    var messenger: EditSender { get }
    
    typealias ItemTreeHandler = (_ success: Bool, _ root: Item?) -> Void
}

class EditSender: Observable
{
    var latestUpdate: Edit? = nil
}

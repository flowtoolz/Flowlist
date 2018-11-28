import SwiftObserver
import SwiftyToolz
import PromiseKit

protocol ItemDatabase: Database
{
    func fetchUpdates() -> Promise<[Edit]>
    func apply(_ edit: Edit)
    
    func fetchTrees() -> Promise<[Item]>
    func resetItemTree(with root: Item) -> Promise<Void>
    
    var messenger: EditSender { get }
}

class EditSender: Observable
{
    var latestUpdate: Edit? = nil
}

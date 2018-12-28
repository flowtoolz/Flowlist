import SwiftObserver
import PromiseKit

protocol ItemDatabase: Database
{
    func fetchUpdates() -> Promise<[Edit]>
    func apply(_ edit: Edit) -> Promise<Void>
    
    func fetchRecords() -> Promise<FetchRecordsResult>
    func reset(tree: Item) -> Promise<Void>
    
    var messenger: EditSender { get }
}

class EditSender: CustomObservable
{
    typealias Message = Edit?
    
    let messenger = Messenger<Edit?>()
}

struct FetchRecordsResult
{
    let records: [Record]
    let dbWasModified: Bool
}

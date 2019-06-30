import SwiftObserver
import PromiseKit

protocol CloudDatabase
{
    func fetchRecords() -> Promise<[Record]>
    
    func fetchChanges() -> Promise<CloudDatabaseChanges>
    var hasChangeToken: Bool { get }
    
    func reset(with records: [Record]) -> Promise<CloudDatabaseSaveResult>
    func save(_ records: [Record]) -> Promise<CloudDatabaseSaveResult>
    func deleteRecords(withIDs ids: [String]) -> Promise<CloudDatabaseDeletionResult>
    
    var queue: DispatchQueue { get }
    
    var messenger: Messenger<CloudDatabaseUpdate?> { get }
}

enum CloudDatabaseUpdate { case mayHaveChanged }

struct CloudDatabaseChanges
{
    let modifiedRecords: [Record]
    let idsOfDeletedRecords: [String]
    var hasChanges: Bool { return modifiedRecords.count + idsOfDeletedRecords.count > 0 }
}

import CloudKit
import Foundation
import SwiftObserver

class StorageController
{
    // MARK: - Singleton Instance
    
    static let shared = StorageController()
    
    private init()
    {
        persister = Persister()
        storage = Storage(with: jsonFile, database: iCloudDatabase)
        
        iCloudDatabase.fetchChanges
        {
            changedRecords, deletionIDs in
            
            print("# changed: \(String(describing: changedRecords?.count))")
            print("# deleted: \(String(describing: deletionIDs?.count))")
        }
    }
    
    // MARK: - System Storage
    
    let iCloudDatabase = ItemICloudDatabase()
    let jsonFile = ItemJSONFile()
    
    // MARK: - Storage Model
    
    let storage: Storage
}

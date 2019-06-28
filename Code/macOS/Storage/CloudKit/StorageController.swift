import CloudKit
import Foundation

class StorageController
{
    // MARK: - Singleton Instance
    
    static let shared = StorageController()
    
    private init()
    {
        Persistent.setupUsingUserDefaults()
        storage = Storage(with: file, database: database)
    }
    
    // MARK: - System Storage
    
    let database = CKItemDatabase()
    let file = ItemJSONFile()
    
    // MARK: - Storage Model
    
    let storage: Storage
}

import CloudKit
import Foundation

class StorageController
{
    // MARK: - Singleton Instance
    
    static let shared = StorageController()
    
    private init()
    {
        persister = Persister()
        storage = Storage(with: file, database: database)
    }
    
    // MARK: - System Storage
    
    let database = ItemICloudDatabase()
    let file = ItemJSONFile()
    
    // MARK: - Storage Model
    
    let storage: Storage
}

extension ItemICloudDatabase: ItemDatabase {}

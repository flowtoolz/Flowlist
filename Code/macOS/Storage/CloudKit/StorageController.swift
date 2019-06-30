import CloudKit
import Foundation

class StorageController
{
    // MARK: - Singleton Instance
    
    static let shared = StorageController()
    
    private init()
    {
        Persistent.setupUsingUserDefaults()
        storage = Storage(with: persister, database: database)
    }
    
    // MARK: - System Storage
    
    let database = CKItemDatabase()
    let persister = FileSystemRecordPersister()
    
    // MARK: - Storage Model
    
    let storage: Storage
}

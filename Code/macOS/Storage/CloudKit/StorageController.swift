import CloudKit
import Foundation

class StorageController
{
    // MARK: - Singleton Instance
    
    static let shared = StorageController()
    
    private init()
    {
        Persistent.setupUsingUserDefaults()
        
        storage = Storage(recordStore: RecordStore(localDatabase: fileSystemDatabase,
                                                   cloudDatabase: cloudKitDatabase))
    }
    
    // MARK: - Database Implementations
    
    let cloudKitDatabase = CloudKitDatabase()
    let fileSystemDatabase = FileSystemDatabase()
    
    // MARK: - Storage Model
    
    let storage: Storage
}

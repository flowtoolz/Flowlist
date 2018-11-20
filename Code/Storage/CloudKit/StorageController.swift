import CloudKit
import Foundation
import SwiftObserver

class StorageController
{
    // MARK: - Singleton Instance
    
    static let shared = StorageController()
    
    private init()
    {
        storage = Storage(with: jsonFile, database: iCloudDatabase)
    }
    
    // MARK: - System Storage
    
    let iCloudDatabase = ItemICloudDatabase()
    let jsonFile = ItemJSONFile()
    
    // MARK: - Storage Model
    
    let storage: Storage
}

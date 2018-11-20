import CloudKit
import Foundation
import SwiftObserver

class StorageController
{
    static let shared = StorageController()
    
    private init()
    {
        Storage.initSharedStorage(with: jsonFile, database: iCloudDatabase)
    }
    
    func appDidLaunch()
    {
        Storage.shared?.appDidLaunch()
    }
    
    let jsonFile = ItemJSONFile()
    let iCloudDatabase = ItemICloudDatabase.shared
}

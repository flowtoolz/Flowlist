import CloudKit
import Foundation
import PromiseKit
import SwiftyToolz

class StorageController
{
    // MARK: - Initialization
    
    static let shared = StorageController()
    
    private init() { Persistent.setupUsingUserDefaults() }
    
    // MARK: - Setup
    
    func appDidLaunch()
    {
        firstly
        {
            JSONFileMigrationController().migrateJSONFile()
        }
        .then
        {
            () -> Promise<Void> in
            
            self.fileController.saveRecordsFromFilesToRecordStore()
            return self.ckRecordController.syncCKRecordsWithFiles()
        }
        .catch
        {
            log(error: $0.readable.message)
        }
    }
    
    // MARK: - Welcome Tour
    
    // TODO: paste welcome tour on app launch if there's no data
    /*
    func pasteWelcomeTourIfRootIsEmpty()
    {
        guard let root = self.root else
        {
            log(warning: "Root is nil.")
            return
        }
        
        if root.isLeaf
        {
            root.insert(Item.welcomeTour, at: 0)
        }
    }
 */
    
    // MARK: - CKRecord Controller
    
    func toggleIntentionToSyncWithDatabase()
    {
        ckRecordController.toggleIntentionToSync()
    }
    
    func networkReachabilityDidUpdate(isReachable: Bool)
    {
        ckRecordController.networkReachabilityDidUpdate(isReachable: isReachable)
    }
    
    func databaseAccountDidChange()
    {
        ckRecordController.accountDidChange()
    }
    
    var isIntendingToSyncWithCloudKitDatabase: Bool
    {
        return ckRecordController.isIntendingToSync
    }
    
    private let ckRecordController = CKRecordController()
    
    // MARK: - Local Storage Controllers
    
    private let fileController = FileController()
    private let recordController = RecordController()
}

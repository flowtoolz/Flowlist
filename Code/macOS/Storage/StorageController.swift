import CloudKit
import Foundation
import PromiseKit
import SwiftyToolz

class StorageController
{
    // MARK: - Initialization
    
    static let shared = StorageController()
    
    private init()
    {
        Persistent.setupUsingUserDefaults()
        
        ckRecordController = CKRecordController()
        fileController = FileController()
        recordController = RecordController()
    }
    
    // MARK: - Respond to Events
    
    func toggleIntentionToSyncWithDatabase()
    {
        ckRecordController.toggleIntentionToSync()
    }
    
    func appDidLaunch()
    {
        firstly
        {
            JSONFileMigrationController().migrateJSONFile()
        }
        .then
        {
            () -> Promise<Void> in
            
            // TODO: we need file system db and record store to provide sender with message to avoid message ping pong, in particular during setup!
            self.fileController.saveRecordsFromFilesToRecordStore()
            return self.ckRecordController.syncCKRecordsWithFiles()
        }
        
        .catch
        {
            log(error: $0.readable.message)
        }
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
    
    // MARK: - Storage Controllers
    
    private let ckRecordController: CKRecordController
    private let fileController: FileController
    private let recordController: RecordController
}

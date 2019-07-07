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
    
    // MARK: - CloudKit Record Controller
    
    func toggleIntentionToSyncWithDatabase()
    {
        ckRecordController.toggleIntentionToSync()
    }
    
    func appDidLaunch()
    {
        firstly
        {
            self.ckRecordController.loadFiles()
        }
        .done
        {
            self.fileController.saveRecordsFromFilesToRecordStore()
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
    
    private let ckRecordController: CKRecordController
    
    // MARK: - Local Storage Controllers
    
    private let fileController: FileController
    
    let recordController: RecordController
}

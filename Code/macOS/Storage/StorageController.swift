import CloudKit
import Foundation
import PromiseKit
import SwiftyToolz

class StorageController
{
    // MARK: - Initialization
    
    static let shared = StorageController()
    private init() { Persistent.setupUsingUserDefaults() }
    
    // MARK: - Setup On Launch
    
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
            return self.ckRecordController.resync()
        }
        .done
        {
            try self.ensureThereIsInitialData()
        }
        .catch(ckRecordController.abortSync)
    }
    
    private func ensureThereIsInitialData() throws
    {
        if TreeStore.shared.count == 0
        {
            TreeStore.shared.add(Item(text: NSFullUserName()))
        }
        
        guard let tree = TreeSelector.shared.selectedTree else
        {
            let message = "Did ensure TreeStore has at least one tree, but TreeSelector still has none selected."
            log(error: message)
            throw ReadableError.message(message)
        }
        
        if TreeSelector.shared.numberOfUserCreatedLeafs.value == 0
        {
            tree.insert(Item.welcomeTour, at: 0)
        }
    }
    
    // MARK: - CKRecord Controller
    
    func toggleIntentionToSyncWithDatabase()
    {
        ckRecordController.userDidToggleSync()
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

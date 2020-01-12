import CloudKit
import Foundation
import PromiseKit
import SwiftyToolz

class StorageController
{
    // MARK: - Initialization
    
    static let shared = StorageController()
    private init() {}
    
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
            return isCKSyncFeatureAvailable ? self.ckRecordController.resync() : Promise()
        }
        .done
        {
            try self.ensureThereIsInitialData()
        }
        .catch
        {
            if isCKSyncFeatureAvailable && CKSyncIntention.shared.isActive
            {
                CKSyncIntention.shared.abort(with: $0)
            }
            else
            {
                log(error: $0.readable.message)
            }
        }
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
            throw message
        }
        
        if TreeSelector.shared.numberOfUserCreatedLeafs.value == 0
        {
            tree.insert(Item.welcomeTour, at: 0)
        }
    }
    
    // MARK: - CKRecord Controller
    
    func toggleIntentionToSyncWithDatabase()
    {
        firstly
        {
            checkWhetherUserWantsToBackupFirst()
        }
        .done
        {
            userWantsToBackupFirst in
            
            if !userWantsToBackupFirst
            {
                self.ckRecordController.toggleSync()
            }
        }
        .catch
        {
            log($0.localizedDescription)
        }
    }
    
    func cloudKitAccountDidChange()
    {
        ckRecordController.accountDidChange()
    }
    
    private let ckRecordController = CKRecordController()
    
    // MARK: - Local Storage Controllers
    
    private let fileController = FileController()
    private let recordController = RecordController()
    
    // MARK: - Show Backup Hint on First Sync
    
    private func checkWhetherUserWantsToBackupFirst() -> Promise<Bool>
    {
        guard !CKSyncIntention.shared.isActive, !didShowBackupHintToUser.value else
        {
            return .value(false)
        }
        
        guard let dialog = Dialog.default else
        {
            return .fail("No default Dialog has been set.")
        }
        
        let backupOption = "I'll Backup My Items First"
        
        let text = """
            It is wise to backup your Flowlist items sometimes, in particular when syncing across different devices.

            To backup your items, select "Data → Show Item Files in Finder".
            Then copy the "Items" folder to a backup location like your DropBox.

            To restore the backup, replace the original "Items" folder with your backup copy and restart Flowlist.

            """
        
        return dialog.pose(Question(title: "How to Backup Your Items",
                                    text: text,
                                    options: ["Start iCloud Sync Now", backupOption]))
        .map
        {
            answer -> Bool in
            self.didShowBackupHintToUser.value = true
            return answer.options.first == backupOption
        }
    }
    
    private var didShowBackupHintToUser = PersistentFlag("UserDefaultsKeyDidShowBackupHint")
}

import SwiftyToolz

class CKSyncIntention
{
    func abort(with error: Error)
    {
        isActive = false
        log(error)
        informUser(aboutSyncError: error)
    }
    
    private func informUser(aboutSyncError error: Error)
    {
        let text =
        """
        \(error.readable.message)

        Make sure 1) Your Mac is online, 2) It is connected to your iCloud account and 3) iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via menu option: Data → Start Using iCloud
        """
        
        let question = Dialog.Question(title: "Whoops, Had to Pause iCloud Sync",
                                       text: text,
                                       options: ["Got it"])
        
        Dialog.default.pose(question, imageName: "icloud_conflict").catch(log)
    }
    
    var isActive: Bool
    {
        get { return persistentFlag.value }
        set { persistentFlag.value = newValue }
    }
    
    private var persistentFlag = PersistentFlag("UserDefaultsKeyWantsToUseICloud")
}

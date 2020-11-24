import SwiftObserver
import SwiftyToolz

class CKSyncIntention
{
    static let shared = CKSyncIntention()
    private init() {}
    
    func abort(with error: Error)
    {
        isActive = false
        log(error: error.ckReadable.message)
        informUser(aboutSyncError: error)
    }
    
    private func informUser(aboutSyncError error: Error)
    {
        let text =
        """
        \(error.ckReadable.message)

        Make sure 1) Your Mac is online, 2) It is connected to your iCloud account and 3) iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via menu option: Data → Start Using iCloud
        """
        
        let question = Question(title: "Whoops, Had to Stop iCloud Sync",
                                text: text,
                                options: ["Got it"])
        
        Dialog.default?.pose(question,
                             imageName: "icloud_conflict").whenFailed { log($0) }
    }
    
    var isActive: Bool
    {
        get { isCKSyncFeatureAvailable ? persistentFlag.value : false }
        set { persistentFlag.value = newValue }
    }
    
    private var persistentFlag = PersistentFlag(defaultsKey)
    
    #if BETA
    private static let defaultsKey = "UserDefaultsKeyWantsToUseICloud_beta"
    #elseif DEBUG
    private static let defaultsKey = "UserDefaultsKeyWantsToUseICloud_debug"
    #else
    private static let defaultsKey = "UserDefaultsKeyWantsToUseICloud"
    #endif
}

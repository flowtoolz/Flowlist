import SwiftyToolz

class CKSyncIntention
{
    func abort(with error: Error)
    {
        abort(withErrorMessage: error.readable.message)
    }
    
    func abort(withErrorMessage message: String, callToAction: String? = nil)
    {
        isActive = false
        
        log(error: message)
        
        let c2a = callToAction ?? "Make sure that 1) Your Mac is online, 2) It is connected to your iCloud account and 3) iCloud Drive is enabled for Flowlist. Then try resuming iCloud sync via the menu: Data → Start Using iCloud"
        
        informUserAboutSyncProblem(error: message, callToAction: c2a)
    }
    
    private func informUserAboutSyncProblem(error: String, callToAction: String)
    {
        let question = Dialog.Question(title: "Whoops, Had to Pause iCloud Sync",
                                       text: "\(error)\n\n\(callToAction)",
                                       options: ["Got it"])
        
        Dialog.default.pose(question, imageName: "icloud_conflict").catch { _ in }
    }
    
    var isActive: Bool
    {
        get { return persistentFlag.value }
        set { persistentFlag.value = newValue }
    }
    
    private var persistentFlag = PersistentFlag("UserDefaultsKeyWantsToUseICloud")
}

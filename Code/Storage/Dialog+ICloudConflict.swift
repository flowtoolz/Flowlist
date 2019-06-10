import SwiftObserver
import PromiseKit

extension Dialog
{
    func askWhetherToPreferICloud() -> Promise<Bool>
    {
        let iCloudOption = "Use iCloud Items"
        
        let question = Question(title: "Conflicting Changes",
                                text: "Seems like you changed local items (on this device) without syncing with iCloud while another device changed the iCloud items.\n\nNow it's unclear how to combine both changes.\n\nDo you want to use the local- or the iCloud version?\nNote that Flowlist will overwrite the other location.",
                                options: ["Use Local Items", iCloudOption])
        
        return firstly
        {
            pose(question, imageName: "icloud_conflict")
        }
        .map(on: DispatchQueue.global(qos: .userInitiated))
        {
            guard $0.options.count == 1, let option = $0.options.first else
            {
                throw ReadableError.message("Unexpected # of answer options")
            }
            
            return option == iCloudOption
        }
    }
}

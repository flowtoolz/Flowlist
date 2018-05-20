import Foundation
import FoundationToolz
import SwiftyToolz

extension TaskStore
{
    func save()
    {
        guard let _ = root.save(to: fileUrl) else
        {
            log(error: "Failed to save tasks to " + fileUrl.absoluteString)
            return
        }
    }
    
    func load()
    {
        guard let loadedRoot = Task(from: fileUrl) else
        {
            log(error: "Failed to load tasks from " + fileUrl.absoluteString)
            return
        }
        
        loadedRoot.recoverSupertasks()
        
        root = loadedRoot
    }
    
    private var fileUrl: URL
    {
        return URL(fileURLWithPath: Bundle.main.bundlePath + "/flowlist.json")
    }
}

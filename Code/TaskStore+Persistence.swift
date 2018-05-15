import Foundation
import FoundationToolz

extension TaskStore
{
    func save()
    {
        guard let _ = root.save(to: fileUrl) else
        {
            print("error: saving to file failed")
            return
        }
    }
    
    func load()
    {
        guard let loadedRoot = Task(from: fileUrl) else
        {
            print("failed to load tasks from " + fileUrl.absoluteString)
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

import FoundationToolz
import SwiftObserver
import SwiftyToolz

extension Store
{
    func load()
    {
        guard let fileUrl = fileUrl, let loadedRoot = Task(from: fileUrl) else
        {
            let fileString = self.fileUrl?.absoluteString ?? "file"
            log(warning: "Failed to load tasks from " + fileString)
            save()
            return
        }
        
        loadedRoot.recoverRoots()
        loadedRoot.title <- NSFullUserName()
        
        root = loadedRoot
    }
    
    func save()
    {
        guard let fileUrl = fileUrl, let _ = root.save(to: fileUrl) else
        {
            let fileString = self.fileUrl?.absoluteString ?? "file"
            log(error: "Failed to save tasks to " + fileString)
            return
        }
        
        root.title <- NSFullUserName()
    }
    
    private var fileUrl: URL?
    {
        return URL.documentDirectory?.appendingPathComponent("flowlist.json")
    }
}

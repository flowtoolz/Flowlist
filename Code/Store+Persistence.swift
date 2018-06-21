import FoundationToolz
import SwiftObserver
import SwiftyToolz

extension Store
{
    func load()
    {
        guard let fileUrl = fileUrl,
            FileManager.default.fileExists(atPath: fileUrl.path)
        else
        {
            return
        }
        
        guard let loadedRoot = Task(from: fileUrl) else
        {
            log(error: "Failed to load tasks from " + fileUrl.absoluteString)
            return
        }
        
        loadedRoot.recoverRoots()
        loadedRoot.title <- NSFullUserName()
        
        root = loadedRoot
        
        Task.numberOfTasks += root.numberOfBranchesRecursively
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
        #if DEBUG
        let filename = "flowlist_debug.json"
        #elseif BETA
        let filename = "flowlist_beta.json"
        #else
        let filename = "flowlist.json"
        #endif
        
        return URL.documentDirectory?.appendingPathComponent(filename)
    }
}

import FoundationToolz
import SwiftObserver
import SwiftyToolz

extension Store
{
    func load()
    {
        guard let loadedRoot = Task(from: fileUrl) else
        {
            log(warning: "Failed to load tasks from " + fileUrl.absoluteString)
            save()
            return
        }
        
        loadedRoot.recoverRoots()
        loadedRoot.title <- bundlePath.fileName
        
        root = loadedRoot
    }
    
    func save()
    {
        guard let _ = root.save(to: fileUrl) else
        {
            log(error: "Failed to save tasks to " + fileUrl.absoluteString)
            return
        }
        
        root.title <- bundlePath.fileName
    }
    
    private var fileUrl: URL
    {
        return URL(fileURLWithPath: bundlePath + "/" + jsonFileName)
    }
    
    private var bundlePath: String { return Bundle.main.bundlePath }
    private var jsonFileName: String { return "flowlist.json" }
}

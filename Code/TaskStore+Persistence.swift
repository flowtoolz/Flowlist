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

extension Task
{
    func debug()
    {
        print(debugDescription())
    }
    
    func debugDescription(_ prefix: String = "", last: Bool = true) -> String
    {
        let bullet = last ? "└╴" : "├╴"
        
        var description = "\(prefix)\(bullet)" + (title.value ?? "untitled")
        
        for i in 0 ..< numberOfSubtasks
        {
            if let st = subtask(at: i)
            {
                let stLast = i == numberOfSubtasks - 1
                let stPrefix = prefix + (last ? " " : "│") + "  "
                
                let stDescription = st.debugDescription(stPrefix, last: stLast)
                
                description += "\n\(stDescription)"
            }
        }
        
        return description
    }
}

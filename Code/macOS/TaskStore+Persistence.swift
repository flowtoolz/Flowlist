import Foundation
import Flowtoolz

extension TaskStore
{
    func save()
    {
        if let url = root.save(to: TaskStore.fileUrl)
        {
            print("did save tasks to " + url.absoluteString)
        }
        else
        {
            print("saving to file failed")
        }
    }
    
    func load()
    {
        let url = TaskStore.fileUrl
        
        guard let loadedRoot = Task(from: url) else
        {
            print("failed to load tasks from " + url.absoluteString)
            return
        }
        
        loadedRoot.setContainers()
        
        root = loadedRoot
        
        print("did load tasks from " + url.absoluteString)
    }
    
    private static var fileUrl: URL
    {
        return URL(fileURLWithPath: Bundle.main.bundlePath + "/flowlist.json")
    }
}

extension Task
{
    enum CodingKeys: String, CodingKey
    {
        case uuid, title, state, elements
    }
}

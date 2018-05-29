import Foundation
import FoundationToolz
import SwiftyToolz

extension Store
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
        if FileManager.default.fileExists(atPath: legacyFilePath)
        {
            loadLegacyFile()
            save()
            try? FileManager.default.removeItem(atPath: legacyFilePath)
            return
        }
        
        guard let loadedRoot = Task(from: fileUrl) else
        {
            log(error: "Failed to load tasks from " + fileUrl.absoluteString)
            return
        }
        
        loadedRoot.recoverRoots()
        
        root = loadedRoot
    }
    
    private var fileUrl: URL
    {
        return URL(fileURLWithPath: Bundle.main.bundlePath + "/flowlist.json")
    }
    
    // MARK: - Legacy
    
    func loadLegacyFile()
    {
        // read task archives
        guard let archive = NSKeyedUnarchiver.unarchiveObject(withFile: legacyFilePath) as? [TaskArchive]
        else
        {
            return
        }
        
        // create task hash map
        var tasksByUuid = [String: Task]()
        
        for archiveTask in archive
        {
            tasksByUuid[archiveTask.uuid] = archiveTask.task
        }
        
        // connect task hierarchy
        for archiveTask in archive
        {
            let task = archiveTask.task
            
            if let elementUuids = archiveTask.elementUuidsForDecoding
            {
                for elementUuid in elementUuids
                {
                    if let element = tasksByUuid[elementUuid]
                    {
                        task.branches.append(element)
                        
                        element.root = task
                    }
                }
            }
        }
        
        // find root and reset
        var potentialUnarchivedRoot: Task?
        
        for task in tasksByUuid.values
        {
            if task.root == nil
            {
                if potentialUnarchivedRoot != nil
                {
                    print("Error: found multiple root containers in unarchived tasks")
                    return
                }
                
                potentialUnarchivedRoot = task
            }
        }
        
        guard let unarchivedRoot = potentialUnarchivedRoot else
        {
            print("Error: found no root container in unarchived tasks")
            return
        }
        
        root = unarchivedRoot
    }
    
    private var legacyFilePath: String
    {
        return Bundle.main.bundlePath + "/UserData.plist"
    }
}

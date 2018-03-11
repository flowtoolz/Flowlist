import Foundation
import Flowtoolz

extension TaskStore
{
    // MARK: - Future Persistence Code
    
    func saveToFile()
    {
        let task = Task()
        task.title = "test title"
        task.state = .inProgress
        
        let subtask = Task()
        task.insert(subtask, at: 0)
        // with a non nil container, encoding crashes...
        //subtask.container = nil
        if let taskData = try? JSONEncoder().encode(task)
        {
            print(taskData.utf8String ?? "error")
        }
        
        // FIXME: encoding causes EXC_BAD_ACCESS
        //root.save(to: "flowlist.json")
    }
    
    func loadFromFile()
    {
        if let loadedRoot = Task(from: "flowlist.json")
        {
            loadedRoot.setContainers()
            
            root = loadedRoot
        }
    }
    
    // MARK: - Old Persistence Code
    
    func save()
    {
        let allTasks = root.allSubtasksRecursively()

        var archive = [TaskArchive]()

        for task in allTasks
        {
            archive.append(TaskArchive(with: task))
        }

        NSKeyedArchiver.archiveRootObject(archive, toFile: TaskStore.filePath)
    }
    
    func load()
    {
        // read task archives
        guard let archive = NSKeyedUnarchiver.unarchiveObject(withFile: TaskStore.filePath) as? [TaskArchive]
        else
        {
            return
        }

        // create task hash map
        var tasksByUuid = [String: Task]()

        for archiveTask in archive
        {
            let task = archiveTask.task

            tasksByUuid[task.uuid] = task
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
                        _ = task.insert(element, at: task.subtasks.count)
                    }
                }
            }
        }

        // find root and reset
        var unarchivedRoot: Task?

        for task in tasksByUuid.values
        {
            if task.container == nil
            {
                if unarchivedRoot != nil
                {
                    print("Error: found multiple root containers in unarchived tasks")
                    return
                }

                unarchivedRoot = task
            }
        }

        guard let root = unarchivedRoot else
        {
            print("Error: found no root container in unarchived tasks")
            return
        }

        store.root = root
    }
    
    private static let filePath = Bundle.main.bundlePath + "/UserData.plist"
}

import Flowtoolz

let store = TaskStore()

class TaskStore: Sender
{
    fileprivate init() {}
    
    var root = Task(with: "Root Task ID", title: "All Items")
    {
        didSet
        {
            send(TaskStore.didUpdateRoot)
        }
    }
    
    static let didUpdateRoot = "TaskStoreDidUpdateRoot"
}

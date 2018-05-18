import SwiftObserver

let store = TaskStore()

class TaskStore
{
    fileprivate init()
    {
        root = Task()
        root.title <- "All Items"
    }
    
    var root: Task
}

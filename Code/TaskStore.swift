import SwiftObserver

let store = TaskStore()

class TaskStore: Observable
{
    fileprivate init() {}
    
    var root = Task(title: "All Items")
    {
        didSet
        {
            send(.didUpdateRoot)
        }
    }
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didUpdateRoot }
}

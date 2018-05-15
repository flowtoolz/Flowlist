import SwiftObserver

let store = TaskStore()

class TaskStore: Observable
{
    fileprivate init() {}
    
    var root = Task(with: "Root Task ID", title: "All Items")
    {
        didSet
        {
            send(.didUpdateRoot)
        }
    }
    
    var latestUpdate: Event { return .didNothing }
    
    enum Event { case didNothing, didUpdateRoot }
}

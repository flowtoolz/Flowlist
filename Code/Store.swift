import SwiftObserver

let store = Store()

class Store: Observer
{
    fileprivate init()
    {
        numberOfTasks <- root.numberOfTasks
        
        observe(newRoot: root)
    }

    var root = Task()
    {
        didSet
        {
            numberOfTasks <- root.numberOfTasks
            
            stopObserving(oldValue)
            observe(newRoot: root)
        }
    }
    
    private func observe(newRoot: Task)
    {
        observe(newRoot)
        {
            [weak self] event in
            
            if case .didChange(let numberOfTasks) = event
            {
                self?.numberOfTasks <- numberOfTasks
            }
        }
    }
    
    let numberOfTasks = Var<Int>()
}

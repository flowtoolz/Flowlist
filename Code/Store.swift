import SwiftObserver

let store = Store()

class Store: Observer
{
    // MARK: - Initialization
    
    fileprivate init()
    {
        updateUserCreatedLeafs(with: root)
        
        observe(newRoot: root)
    }

    // MARK: - Root
    
    var root = Task()
    {
        didSet
        {
            updateUserCreatedLeafs(with: root)
            
            stopObserving(oldValue)
            observe(newRoot: root)
        }
    }
    
    private func observe(newRoot: Task)
    {
        observe(newRoot)
        {
            [weak self, weak newRoot] event in
            
            guard let newRoot = newRoot else { return }
            
            self?.didReceive(event, from: newRoot)
        }
    }
    
    // MARK: - Count Leafs Inside Root
    
    private func didReceive(_ event: Task.Event, from root: Task)
    {
        if case .didChange(_) = event
        {
            updateUserCreatedLeafs(with: root)
        }
        else if case .did(let edit) = event, edit.changesItems
        {
            updateUserCreatedLeafs(with: root)
        }
    }
    
    private func updateUserCreatedLeafs(with root: Task)
    {
        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var<Int>()
}

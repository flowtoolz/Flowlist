import SwiftObserver

class Store: StoreInterface, Observer
{
    // MARK: - Initialization
    
    static let shared = Store() 
    
    fileprivate init()
    {
        updateUserCreatedLeafs(with: root)
        
        observe(newRoot: root)
    }

    // MARK: - Root
    
    var root = Item()
    {
        didSet
        {
            updateUserCreatedLeafs(with: root)
            
            stopObserving(oldValue)
            observe(newRoot: root)
        }
    }
    
    private func observe(newRoot: Item)
    {
        observe(newRoot)
        {
            [weak self, weak newRoot] event in
            
            guard let newRoot = newRoot else { return }
            
            self?.didReceive(event, from: newRoot)
        }
    }
    
    // MARK: - Welcome Tour
    
    func pasteWelcomeTourIfRootIsEmpty()
    {
        if root.isLeaf
        {
            root.insert(Item.welcomeTour, at: 0)
        }
    }
    
    // MARK: - Count Leafs Inside Root
    
    private func didReceive(_ event: Item.Event, from root: Item)
    {
        if case .didChange(_) = event
        {
            updateUserCreatedLeafs(with: root)
        }
        else if case .did(let edit) = event, edit.modifiesContent
        {
            updateUserCreatedLeafs(with: root)
        }
    }
    
    private func updateUserCreatedLeafs(with root: Item)
    {
        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var<Int>()
}

typealias PersistableStore = Persistable & StoreInterface

protocol StoreInterface: AnyObject {}

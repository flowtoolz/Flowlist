import SwiftObserver
import SwiftyToolz

class RootStore: Observer, CustomObservable
{
    // MARK: - Manage Roots
    
    subscript(_ id: ItemData.ID) -> Item?
    {
        return roots[id]
    }
    
    func add(_ root: Item)
    {
        guard root.root != nil else
        {
            return log(error: "Tried to save Item as roor which is no root.")
        }
        
        observeTreeMessenger(of: root)
        roots[root.id] = root
    }
    
    func remove(_ root: Item)
    {
        stopObserving(roots[root.id]?.treeMessenger)
        roots[root.id] = nil
    }
    
    // MARK: - Forward Tree Updates To Observers
    
    private func observeTreeMessenger(of root: Item)
    {
        observe(root.treeMessenger).map
        {
            event -> Item.Event.TreeUpdate? in
            
            guard case .didUpdateTree(let treeUpdate) = event else { return nil }
            
            return treeUpdate
        }
        .receive
        {
            [weak self] in if let treeUpdate = $0 { self?.send(treeUpdate) }
        }
    }
    
    let messenger = Messenger<Message>()
    typealias Message = Item.Event.TreeUpdate?
    
    // MARK: - Storage
    
    private let roots = HashMap()
}

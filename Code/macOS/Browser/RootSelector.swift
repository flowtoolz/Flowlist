import SwiftObserver

class RootSelector: Observer, CustomObservable
{
    // MARK: - Initialization
    
    static let shared = RootSelector()
    
    private init()
    {
        observe(ItemStore.shared)
        {
            [weak self] in if let event = $0 { self?.itemStoreDidSend(event) }
        }
    }
    
    // MARK: - Select Root from ItemStore
    
    private func itemStoreDidSend(_ event: ItemStore.Event)
    {
        // TODO: Test this root selection strategy which uses the first root it gets ...
        switch event
        {
        case .someTreeDidChange:
            break
            
        case .didAddRoot(let root):
            if selectedRoot == nil { select(root: root) }
            
        case .didRemoveRoot(let root):
            if selectedRoot === root { select(root: nil) }
        }
    }
    
    private func select(root newRoot: Item?)
    {
        stopObserving(selectedRoot?.treeMessenger)

        if let newRoot = newRoot
        {
            observeTreeMessenger(of: newRoot)
            updateUserCreatedLeafs(with: newRoot)
        }
        else
        {
            numberOfUserCreatedLeafs <- 0
        }
        
        selectedRoot = newRoot
        DispatchQueue.main.async { self.send(newRoot) }
    }
    
    private(set) weak var selectedRoot: Item?
    
    // MARK: - Track Number of User Created Leafs in Selected Root
    
    private func observeTreeMessenger(of newRoot: Item)
    {
        observe(newRoot.treeMessenger)
        {
            [weak self, weak newRoot] event in
            
            guard let newRoot = newRoot else { return }
            
            self?.didReceive(event, from: newRoot)
        }
    }
    
    private func didReceive(_ event: Item.Event, from root: Item)
    {
        switch event
        {
        case .didNothing, .didUpdateTree:
            break
            
        case .didUpdateNode(let edit):
            if edit.modifiesGraphStructure
            {
                updateUserCreatedLeafs(with: root)
            }
            
        case .didChangeLeafNumber(_):
            updateUserCreatedLeafs(with: root)
        }
    }
    
    private func updateUserCreatedLeafs(with root: Item)
    {
        numberOfUserCreatedLeafs <- root.isLeaf ? 0 : root.numberOfLeafs
    }
    
    let numberOfUserCreatedLeafs = Var(0)
    
    // MARK: - Observability
    
    let messenger = Messenger<Message>()
    typealias Message = Item?
}
